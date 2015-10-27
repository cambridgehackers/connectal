
// Copyright (c) 2014 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#undef NDEBUG
#include "portalmat.h"
#include "rbm.h"
#include "mnist.h"

float sigmoid(float x)
{
  if (x < -8.0)
    x = -8.0;
  if (x > 8.0)
    x = 8.0;
  return 1 / (1 + expf(-x));
}

void configureSigmoidTable()
{
  sigmoiddevice->tableSize();
  sem_wait(&mul_sem);

  int num_entries = sigmoidindication->tableSize();
  int addrsize = log((double)num_entries) / log(2.0);

  float range = 16.0;
  float lowest_angle = - range/2.0;
  double fincr = (float)num_entries / range;
  double fscale = num_entries / range;
  fprintf(stderr, "configureSigmoidTable: num_entries=%d addrsize=%d fscale=%f fincr=%f\n", num_entries, addrsize, fscale, fincr);

  RbmMat sigmoidTable;
  // each entry consists of [-angle, sigmoid(angle), derivative, 0]
  sigmoidTable.create(1, 4*num_entries, CV_32F);

  // v = (index-num_entries/2) / fscale
  // index = v * fscale + num_entries/2

  float fxscale = fscale;
  float fxllimit = (float)lowest_angle;
  float fxulimit = (float)-lowest_angle;
  fprintf(stderr, "configureSigmoidTable num_entries=%d rscale=%f %x llimit=%f %x rlimit=%f %x\n",
	  num_entries, fxscale, *(int*)&fxscale, fxllimit, *(int*)&fxllimit, fxulimit, *(int*)&fxulimit);
  sigmoiddevice->setLimits(*(int*)&fxscale, *(int*)&fxllimit, *(int*)&fxulimit);

  int incr = 1;
  fprintf(stderr, "filling sigmoid table pointer=%x\n", sigmoidTable.reference());
  for (int ai = 0; ai < num_entries; ai += incr) {
    float angle = (ai - num_entries / 2) / fscale;
    //int index = (int)(angle*fscale);
    float s = sigmoid(angle);
    //fprintf(stderr, "ai=%d angle=%f entry_angle=%f sigmoid=%f\n", ai, angle, angle * fscale + num_entries/2, s);
    sigmoidTable.at<float>(0, 4*ai+0) = -angle;
    sigmoidTable.at<float>(0, 4*ai+1) = s;
    if (ai == num_entries-1) {
      sigmoidTable.at<float>(0, 4*ai+2) = 0;
    } else if (ai > 0) {
      float angle_prev = (ai - 1 - num_entries/2) / fscale;
      float s_prev = sigmoidTable.at<float>(0,4*(ai-1)+1);
      float dangle = angle - angle_prev;
      float ds = s - s_prev;
      float slope = ds / dangle;
      //fprintf(stderr, "angle=%f angle_prev=%f s=%f s_prev=%f ds=%f dangle=%f slope=%f\n", angle, angle_prev, s, s_prev, ds, dangle, slope);
      sigmoidTable.at<float>(0, 4*ai+2) = slope;
    }
    sigmoidTable.at<float>(0, 4*ai+3) = 0;
  }
  fprintf(stderr, "updating sigmoid table pointer=%x\n", sigmoidTable.reference());
  sigmoiddevice->updateTable(sigmoidTable.reference(), 0, num_entries);
  sem_wait(&mul_sem);
  fprintf(stderr, "sigmoid table updated\n");
}


void RbmMat::sigmoid(RbmMat &a)
{
    create(a.rows, a.cols, CV_32F);
    fprintf(stderr, "RbmMat::sigmoid() %d %d\n", a.rows, a.cols);
    reference();
    cacheFlushInvalidate();
    //fprintf(stderr, "sigmoid: a.ref=%d a.rows=%d a.cols=%d\n", a.reference(), a.rows, a.cols);
    //fprintf(stderr, "sigmoiddevice->sigmoid\n");
    sigmoiddevice->sigmoid(a.reference(), 0, reference(), 0, a.rows*a.cols);
    sem_wait(&mul_sem);
}

void RbmMat::hiddenStates(RbmMat &a, RbmMat &rand)
{
    create(a.rows, a.cols, CV_32F);
    fprintf(stderr, "hiddenStates: a.ref=%d a.rows=%d a.cols=%d\n", a.reference(), a.rows, a.cols);
    rand.reference();
    reference();
    cacheFlushInvalidate();
    fprintf(stderr, "rbmdevice->computeStates ptr=%d randPtr=%d\n", a.reference(), rand.reference());
    rbmdevice->computeStates(a.reference(), 0, rand.reference(), 0, reference(), 0, a.rows*a.cols);
    sem_wait(&mul_sem);
}

// weights += learningRate * (pos_associations - neg_associations) / num_examples;
void RbmMat::updateWeights(RbmMat &posAssociations, RbmMat &negAssociations, float learningRateOverNumExamples)
{
    fprintf(stderr, "rbmdevice->updateWeights pa.ref=%d na.ref=%d\n", posAssociations.reference(), negAssociations.reference());
    cacheFlushInvalidate();
    rbmdevice->updateWeights(posAssociations.reference(), negAssociations.reference(), reference(), rows*cols, *(int*)&learningRateOverNumExamples);
    sem_wait(&mul_sem);
}

void RbmMat::sumOfErrorSquared(RbmMat &pred)
{
    if (rows != pred.rows || cols != pred.cols) {
	fprintf(stderr, "Mismatched data and pred: data.rows=%d data.cols=%d  pred.rows=%d pred.cols=%d\n",
		rows, cols, pred.rows, pred.cols);
	exit(-1);
    }
    fprintf(stderr, "sumOfErrorSquared called numElts=%d\n", rows*cols);
    cacheFlushInvalidate();
    rbmdevice->sumOfErrorSquared(reference(), pred.reference(), rows*cols);
    sem_wait(&mul_sem);
}

void printDynamicRange(const char *label, cv::Mat m)
{
  int min_exp = 0;
  int max_exp = 0;
  float min_val = 0.0;
  float max_val = 0.0;
  dynamicRange(m, &min_exp, &max_exp, &min_val, &max_val);
  printf("dynamic range: max_exp=%d min_exp=%d max_val=%f min_val=%f  %s\n", max_exp, min_exp, max_val, min_val, label);
}

float sumOfErrorSquared(cv::Mat &a, cv::Mat &b)
{
  cv::Mat diff = a - b;
  float error = diff.dot(diff);
  return error;
}

void RBM::train(int numVisible, int numHidden, const cv::Mat &trainingData)
{
  bool verify = false;
#ifdef SIMULATION
  int numEpochs = 10;
#else
  int numEpochs = 100;
#endif
  if (verify)
    numEpochs = 1;
  float sum_of_errors_squareds[numEpochs];
  bool verbose = false;
  bool dynamicRange = true;
  //int numExamples = trainingData.rows;

  if (verbose) dumpMat<float>("trainingData", "%5.6f", trainingData);
  if (dynamicRange) printDynamicRange("trainingData", trainingData);

  cv::Mat weights;
  weights.create(numVisible+1, numHidden+1, CV_32F);
  for (int i = 0; i < numVisible+1; i++) {
    for (int j = 0; j < numHidden+1; j++) {
      float w = 0.1 * drand48();
      if (w < 0 || w > 1.0)
	printf("w out of range %f\n", w);
      weights.at<float>(i,j) = w;
    }
  }
  if (dynamicRange) printDynamicRange("weights", weights);

  // insert bias units of 1 into first column of data
  cv::Mat data;
  data.create(trainingData.rows, trainingData.cols+1, CV_32F);
  trainingData.copyTo(data.colRange(1, data.cols));
  for (int i = 0; i < data.rows; i++)
    data.at<float>(i, 0) = 1.0;

  RbmMat pmData(data);
  RbmMat pmDataT(pmData.t());
  RbmMat pmWeights(weights);
  RbmMat pmWeightsT;
  RbmMat pm_pos_hidden_activations;
  RbmMat pm_pos_hidden_probs;
  RbmMat pm_rand_mat;
  RbmMat pm_pos_hidden_states;
  RbmMat pm_pos_hidden_probsT;
  RbmMat pm_pos_associations;
  RbmMat pm_neg_visible_activations;
  RbmMat pm_neg_visible_probs;
  RbmMat pm_neg_hidden_activations;
  RbmMat pm_neg_hidden_probs;
  RbmMat pm_neg_visible_probsT;
  RbmMat pm_neg_hidden_probsT;
  RbmMat pm_neg_associations;
  RbmMat pm_pos_hidden_statesT;

  if (verbose) dumpMat<float>("data", "%5.6f", data);
  if (verbose) dumpMat<float>("weights", "%5.6f", weights);

  portalTimerStart(0);
  for (int epoch = 0; epoch < numEpochs; epoch++) {

    timerdevice->startTimer();
    cv::Mat pos_hidden_activations = data * pmWeights;
    if (dynamicRange) printDynamicRange("pos_hidden_activations", pos_hidden_activations);
    // fixme transpose
    pmWeightsT.transpose(pmWeights);
    if (verbose) dumpMat<float>("pmWeightsT", "%5.1f", pmWeightsT);

    //RbmMat pm_pos_hidden_activations;
    pm_pos_hidden_activations.multf(pmDataT, pmWeights);
    if (verbose) dumpMat<float>("pm_pos_hidden_activations", "%5.1f", pm_pos_hidden_activations);
    if (verbose) dumpMat<float>("   pos_hidden_activations", "%5.1f", pos_hidden_activations);

    if (verify) assert(pm_pos_hidden_activations.compare(pos_hidden_activations, __FILE__, __LINE__));
    // RbmMat pm_pos_hidden_probs;
    pm_pos_hidden_probs.sigmoid(pm_pos_hidden_activations);
    if (dynamicRange) printDynamicRange("pm_pos_hidden_probs", pm_pos_hidden_probs);

    cv::Mat pos_hidden_probs(pm_pos_hidden_activations);
    for (int i = 0; i < pm_pos_hidden_activations.rows; i++) {
      for (int j = 0; j < pm_pos_hidden_activations.cols; j++) {
	pos_hidden_probs.at<float>(i,j) = sigmoid(pm_pos_hidden_activations.at<float>(i,j));
      }
    }
    if (verbose) dumpMat<float>("pm_pos_hidden_probs", "%5.1f", pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("   pos_hidden_probs", "%5.1f", pos_hidden_probs);
    if (verify) assert(pm_pos_hidden_probs.compare(pos_hidden_probs, __FILE__, __LINE__));

    // RbmMat pm_rand_mat;
    pm_rand_mat.create(pm_pos_hidden_probs.rows, pm_pos_hidden_probs.cols, CV_32F);
    for (int i = 0; i < pm_pos_hidden_probs.rows; i++) {
      for (int j = 0; j < pm_pos_hidden_probs.cols; j++) {
	pm_rand_mat.at<float>(i,j) = (float)drand48();
      }
    }
    if (verbose) dumpMat<float>("pm_rand_mat", "%5.1f", pm_rand_mat);
    if (dynamicRange) printDynamicRange("pm_rand_mat", pm_rand_mat);
    cv::Mat pos_hidden_states;
    pos_hidden_states.create(pm_pos_hidden_probs.rows, pm_pos_hidden_probs.cols, CV_32F);
    for (int i = 0; i < pm_pos_hidden_probs.rows; i++) {
      for (int j = 0; j < pm_pos_hidden_probs.cols; j++) {
	float val = 0.0;
	if (pm_pos_hidden_probs.at<float>(i,j) > pm_rand_mat.at<float>(i,j))
	  val = 1.0;
	pos_hidden_states.at<float>(i,j) = val;
      }
    }
    if (dynamicRange) printDynamicRange("pos_hidden_states", pos_hidden_states);

    // RbmMat pm_pos_hidden_states;
    pm_pos_hidden_states.hiddenStates(pm_pos_hidden_probs, pm_rand_mat);

    if (verbose) dumpMat<float>("pm_pos_hidden_states", "%5.1f", pm_pos_hidden_states);
    if (verbose) dumpMat<float>("   pos_hidden_states", "%5.1f", pos_hidden_states);
    if (verify) assert(pm_pos_hidden_states.compare(pos_hidden_states, __FILE__, __LINE__));
    if (verbose) dumpMat<float>("pmDataT", "%5.1f", pmDataT);

    //RbmMat pmWeights(weights); // back to non-transposed
    //pmWeights.copy(weights);
    if (verbose) dumpMat<float>("pmWeights", "%5.1f", pmWeights);

    pm_pos_hidden_probsT.transpose(pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("pos_hidden_probsT", "%5.1f", pm_pos_hidden_probsT);

    cv::Mat pos_associations = pmDataT * pm_pos_hidden_probs;

    //RbmMat pm_pos_associations;
    pm_pos_associations.multf(pmData, pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("pos_associations", "%5.1f", pm_pos_associations);
    if (dynamicRange) printDynamicRange("pm_pos_associations", pm_pos_associations);

    // check results
    if (verify) assert(pm_pos_associations.compare(pos_associations, __FILE__, __LINE__));

    // RbmMat pm_neg_visible_activations;
    pm_pos_hidden_statesT.transpose(pm_pos_hidden_states);
    pm_neg_visible_activations.multf(pm_pos_hidden_statesT, pmWeightsT);
    if (verbose) dumpMat<float>("neg_visible_activations", "%5.1f", pm_neg_visible_activations);
    if (dynamicRange) printDynamicRange("pm_neg_visible_activations", pm_neg_visible_activations);

    cv::Mat neg_visible_probs;
    neg_visible_probs.create(pm_neg_visible_activations.rows, pm_neg_visible_activations.cols, CV_32F);
    for (int i = 0; i < pm_neg_visible_activations.rows; i++) {
      for (int j = 0; j < pm_neg_visible_activations.cols; j++) {
	neg_visible_probs.at<float>(i,j) = sigmoid(pm_neg_visible_activations.at<float>(i,j));
      }
    }

    // RbmMat pm_neg_visible_probs;
    pm_neg_visible_probs.sigmoid(pm_neg_visible_activations);
    pm_neg_visible_probsT.transpose(pm_neg_visible_probs);
    if (verbose) dumpMat<float>("neg_visible_probs", "%5.1f", pm_neg_visible_probs);

    // pm_neg_visible_probs[:0] = 1;
    for (int i = 0; i < pm_neg_visible_probs.rows; i++) {
      pm_neg_visible_probs.at<float>(i,0) = 1.0;
      neg_visible_probs.at<float>(i,0) = 1.0;
    }
    if (dynamicRange) printDynamicRange("pm_neg_visible_probs", pm_neg_visible_probs);
    if (verify) assert(pm_neg_visible_probs.compare(neg_visible_probs, __FILE__, __LINE__));

    // RbmMat pm_neg_hidden_activations;
    pm_neg_hidden_activations.multf(pm_neg_visible_probsT, pmWeights);
    if (verbose) dumpMat<float>("pm_neg_hidden_activations", "%5.1f", pm_neg_hidden_activations);
    if (dynamicRange) printDynamicRange("pm_neg_hidden_activations", pm_neg_hidden_activations);

    cv::Mat neg_hidden_activations = pm_neg_visible_probs * pmWeights;
    if (verbose) dumpMat<float>("   neg_hidden_activations", "%5.1f", neg_hidden_activations);
    if (verify) assert(pm_neg_hidden_activations.compare(neg_hidden_activations, __FILE__, __LINE__, 0.05));

    // RbmMat pm_neg_hidden_probs;
    pm_neg_hidden_probs.sigmoid(pm_neg_hidden_activations);
    if (verbose) dumpMat<float>("pm_neg_hidden_probs", "%5.1f", pm_neg_hidden_probs);
    if (dynamicRange) printDynamicRange("pm_neg_hidden_probs", pm_neg_hidden_probs);

    pm_neg_visible_probsT.transpose(pm_neg_visible_probs);
    if (verbose) dumpMat<float>("pm_neg_visible_probsT", "%5.1f", pm_neg_visible_probsT);
    if (dynamicRange) printDynamicRange("pm_neg_visible_probs", pm_neg_visible_probs);

    pm_neg_hidden_probsT.transpose(pm_neg_hidden_probs);
    //RbmMat pm_neg_associations;
    pm_neg_associations.multf(pm_neg_visible_probs, pm_neg_hidden_probs);
    if (verbose) dumpMat<float>("pm_neg_associations", "%5.1f", pm_neg_associations);
    cv::Mat neg_associations = pm_neg_visible_probsT * pm_neg_hidden_probs;
    if (verbose) dumpMat<float>("   neg_associations", "%5.1f", neg_associations);
    if (dynamicRange) printDynamicRange("pm_neg_associations", pm_neg_associations);

    if (verbose) dumpMat<float>("pmWeights.before", "%5.1f", pmWeights);
    // weights += learningRate * (pos_associations - neg_associations) / num_examples;
    float learningRate = 1.0;
    float num_examples = data.rows;
    pmWeights.updateWeights(pm_pos_associations, pm_neg_associations, learningRate / num_examples);
    if (verbose) dumpMat<float>("pmWeights.after ", "%5.1f", pmWeights);
    if (dynamicRange) printDynamicRange("weights", weights);

fprintf(stderr, "========== %s:%d\n", __FILE__, __LINE__);
    // error = np.sum((data - neg_visible_probs) ** 2)
    pmData.sumOfErrorSquared(pm_neg_visible_probs);
    float error = sumOfErrorSquared(data, pm_neg_visible_probs);
fprintf(stderr, "========== %s:%d\n", __FILE__, __LINE__);
    fprintf(stderr, "completed epoch %d sumOfErrorSquared=%f\n", epoch, error);
    sum_of_errors_squareds[epoch] = rbmDeviceIndication->sum_of_errors_squared;
    timerdevice->stopTimer();
  }
  //uint64_t total_cycles = portalTimerLap(0);
  //uint64_t beats = hostMemServerIndication->getMemoryTraffic(ChannelType_Read);
  //fprintf(stderr, "total_cycles=%ld beats=%ld utilization=%f\n", (long)total_cycles, (long)beats, (float)beats / (float)total_cycles);
  for(int i = 0; i < numEpochs; i++)
    fprintf(stderr, "(%d) %f\n", i, sum_of_errors_squareds[i]);
}

void RBM::run()
{
  cv::Mat trainingData = (cv::Mat_<float>(6,6) <<
			  1,1,1,0,0,0,
			  1,0,1,0,0,0,
			  1,1,1,0,0,0,
			  0,0,1,1,1,0,
			  0,0,1,1,0,0,
			  0,0,1,1,1,0);

  char name_buff[256];
  snprintf(name_buff, 256, "../train-images-idx3-ubyte");
  fprintf(stderr, "reading image data from %s\n", name_buff);
  MnistImageFile imagefile(name_buff);
  imagefile.open();
  int numImages = imagefile.numEntries();
  int numPixels = imagefile.rows()*imagefile.cols();
  
  numImages = 200;
  int cols = 783; // one more column is added below to make the total 784.
#ifdef SIMULATION
  numImages = 32;
  cols = 31; // one more column is added to make the total 32
#endif
  if (!cols || numPixels < cols)
    cols = numPixels;
  fprintf(stderr, "numImages=%d numPixels=%d imagefile.rows=%d imagefile.cols=%d\n", numImages, numPixels, imagefile.rows(), imagefile.cols());
  
  //numVisible = imagefile.rows()*imagefile.cols();
  int numVisible = cols;
  int numHidden = numVisible / 2;
  
  trainingData.create(numImages, cols, CV_32F);
  
  for (int i = 0; i < numImages; i++) {
    //fprintf(stderr, "Reading mat %d\n", i);
    cv::Mat m = imagefile.mat(i);
    //dumpMat<unsigned char>("foo", "%02x", m);
    for (int j = 0; j < imagefile.rows(); j++) {
      for (int k = 0; k < imagefile.cols(); k++) {
	int offset = j*imagefile.cols() + k;
	if (offset < cols) {
	  float f = (float)m.at<unsigned char>(k,j);
	  trainingData.at<float>(i, offset) = f;
	}
      }
    }
  }

  fprintf(stderr, "RBM::run() invoking train\n");
  train(numVisible, numHidden, trainingData);
  fprintf(stderr, "trainingData.rows=%d trainingData.cols=%d\n", trainingData.rows, trainingData.cols);
}
