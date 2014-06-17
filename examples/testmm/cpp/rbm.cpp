
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

#include "portalmat.h"
#include "rbm.h"
#include "mnist.h"

void RBM::train(int numVisible, int numHidden, const cv::Mat &trainingData)
{
  int numExamples = trainingData.rows;

  cv::Mat weights;
  weights.create(numVisible+1, numHidden+1, CV_32F);
  for (int i = 1; i < numVisible+1; i++) {
    for (int j = 1; j < numHidden+1; j++) {
      weights.at<float>(i,j) = 0.1 * drand48();
    }
  }

  // insert bias units of 1 into first column of data
  cv::Mat data;
  data.create(trainingData.rows, trainingData.cols+1, CV_32F);
  trainingData.copyTo(data.colRange(1, data.cols));
  for (int i = 0; i < data.rows; i++)
    data.at<float>(i, 0) = 1.0;

  PortalMat pmData(data);
  PortalMat dataT(pmData.t());

  PortalMat pmWeights(weights);
  PortalMat pmWeightsCM;
  PortalMat pm_pos_hidden_activations;
  PortalMat pm_pos_hidden_probs;
  PortalMat pm_rand_mat;
  PortalMat pm_pos_hidden_states;
  PortalMat pm_pos_hidden_probsT;
  PortalMat pm_pos_associations;
  PortalMat pm_neg_visible_activations;
  PortalMat pm_neg_visible_probs;
  PortalMat pm_neg_hidden_activations;
  PortalMat pm_neg_hidden_probs;
  PortalMat pm_neg_visible_probsT;
  PortalMat pm_neg_hidden_probsT;
  PortalMat pm_neg_associations;

  int numEpochs = 1;
  bool verbose = false;
  bool verify = false;
  if (verbose) dumpMat<float>("data", "%5.1f", data);
  if (verbose) dumpMat<float>("weights", "%5.1f", weights);

  start_timer(0);
  dma->show_mem_stats(ChannelType_Read);
  for (int epoch = 0; epoch < numEpochs; epoch++) {

    timerdevice->startTimer();
    cv::Mat pos_hidden_activations = data * pmWeights;

    // fixme transpose
    pmWeightsCM.transpose(pmWeights);
    if (verbose) dumpMat<float>("pmWeightsCM", "%5.1f", pmWeightsCM);

    //PortalMat pm_pos_hidden_activations;
    pm_pos_hidden_activations.multf(pmData, pmWeightsCM);
    if (verbose) dumpMat<float>("pm_pos_hidden_activations", "%5.1f", pm_pos_hidden_activations);
    if (verbose) dumpMat<float>("   pos_hidden_activations", "%5.1f", pos_hidden_activations);

    if (verify) assert(pm_pos_hidden_activations.compare(pos_hidden_activations, __FILE__, __LINE__));

    // PortalMat pm_pos_hidden_probs;
    pm_pos_hidden_probs.create(pos_hidden_activations.rows, pos_hidden_activations.cols, CV_32F);
    pm_pos_hidden_probs.sigmoid(pm_pos_hidden_activations);

    cv::Mat pos_hidden_probs(pm_pos_hidden_activations);
    for (int i = 0; i < pm_pos_hidden_activations.rows; i++) {
      for (int j = 0; j < pm_pos_hidden_activations.cols; j++) {
	pos_hidden_probs.at<float>(i,j) = sigmoid(pm_pos_hidden_activations.at<float>(i,j));
      }
    }
    if (verbose) dumpMat<float>("pm_pos_hidden_probs", "%5.1f", pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("   pos_hidden_probs", "%5.1f", pos_hidden_probs);
    if (verify) assert(pm_pos_hidden_probs.compare(pos_hidden_probs, __FILE__, __LINE__, .001, &pos_hidden_activations));

    // PortalMat pm_rand_mat;
    pm_rand_mat.create(pm_pos_hidden_probs.rows, pm_pos_hidden_probs.cols, CV_32F);
    for (int i = 0; i < pm_pos_hidden_probs.rows; i++) {
      for (int j = 0; j < pm_pos_hidden_probs.cols; j++) {
	pm_rand_mat.at<float>(i,j) = (float)drand48();
      }
    }
    if (verbose) dumpMat<float>("pm_rand_mat", "%5.1f", pm_rand_mat);
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


    // PortalMat pm_pos_hidden_states;
    if (1) // verify
      pm_pos_hidden_states.hiddenStates2(pm_pos_hidden_probs, pm_rand_mat);
    else
      pm_pos_hidden_states.hiddenStates(pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("pm_pos_hidden_states", "%5.1f", pm_pos_hidden_states);
    if (verbose) dumpMat<float>("   pos_hidden_states", "%5.1f", pos_hidden_states);
    if (verify) assert(pm_pos_hidden_states.compare(pos_hidden_states, __FILE__, __LINE__));

    if (verbose) dumpMat<float>("dataT", "%5.1f", dataT);

    //PortalMat pmWeights(weights); // back to non-transposed
    //pmWeights.copy(weights);
    if (verbose) dumpMat<float>("pmWeights", "%5.1f", pmWeights);

    pm_pos_hidden_probsT.transpose(pm_pos_hidden_probs);
    if (verbose) dumpMat<float>("pos_hidden_probsT", "%5.1f", pm_pos_hidden_probsT);

    cv::Mat pos_associations = dataT * pm_pos_hidden_probs;

    //PortalMat pm_pos_associations;
    pm_pos_associations.multf(dataT, pm_pos_hidden_probsT);
    if (verbose) dumpMat<float>("pos_associations", "%5.1f", pm_pos_associations);

    // check results
    if (verify) assert(pm_pos_associations.compare(pos_associations, __FILE__, __LINE__));

    // PortalMat pm_neg_visible_activations;
    pm_neg_visible_activations.multf(pm_pos_hidden_states, pmWeights);
    if (verbose) dumpMat<float>("neg_visible_activations", "%5.1f", pm_neg_visible_activations);

    cv::Mat neg_visible_probs;
    neg_visible_probs.create(pm_neg_visible_activations.rows, pm_neg_visible_activations.cols, CV_32F);
    for (int i = 0; i < pm_neg_visible_activations.rows; i++) {
      for (int j = 0; j < pm_neg_visible_activations.cols; j++) {
	neg_visible_probs.at<float>(i,j) = sigmoid(pm_neg_visible_activations.at<float>(i,j));
      }
    }
    // PortalMat pm_neg_visible_probs;
    pm_neg_visible_probs.sigmoid(pm_neg_visible_activations);
    if (verbose) dumpMat<float>("neg_visible_probs", "%5.1f", pm_neg_visible_probs);

    // pm_neg_visible_probs[:0] = 1;
    for (int i = 0; i < pm_neg_visible_probs.rows; i++) {
      pm_neg_visible_probs.at<float>(i,0) = 1.0;
      neg_visible_probs.at<float>(i,0) = 1.0;
    }
    if (verify) pm_neg_visible_probs.compare(neg_visible_probs, __FILE__, __LINE__, .001, &pm_neg_visible_activations);

    // PortalMat pm_neg_hidden_activations;
    pm_neg_hidden_activations.multf(pm_neg_visible_probs, pmWeightsCM);
    if (verbose) dumpMat<float>("pm_neg_hidden_activations", "%5.1f", pm_neg_hidden_activations);

    cv::Mat neg_hidden_activations = pm_neg_visible_probs * pmWeights;
    if (verbose) dumpMat<float>("   neg_hidden_activations", "%5.1f", neg_hidden_activations);
    if (verify) pm_neg_hidden_activations.compare(neg_hidden_activations, __FILE__, __LINE__);

    // PortalMat pm_neg_hidden_probs;
    pm_neg_hidden_probs.sigmoid(pm_neg_hidden_activations);
    if (verbose) dumpMat<float>("pm_neg_hidden_probs", "%5.1f", pm_neg_hidden_probs);

    pm_neg_visible_probsT.transpose(pm_neg_visible_probs);
    if (verbose) dumpMat<float>("pm_neg_visible_probsT", "%5.1f", pm_neg_visible_probsT);

    pm_neg_hidden_probsT.transpose(pm_neg_hidden_probs);
    //PortalMat pm_neg_associations;
    pm_neg_associations.multf(pm_neg_visible_probsT, pm_neg_hidden_probsT);
    if (verbose) dumpMat<float>("pm_neg_associations", "%5.1f", pm_neg_associations);
    cv::Mat neg_associations = pm_neg_visible_probsT * pm_neg_hidden_probs;
    if (verbose) dumpMat<float>("   neg_associations", "%5.1f", neg_associations);


    if (verbose) dumpMat<float>("pmWeights.before", "%5.1f", pmWeights);
    // weights += learningRate * (pos_associations - neg_associations) / num_examples;
    float learningRate = 1.0;
    float num_examples = data.rows;
    pmWeights.updateWeights(pm_pos_associations, pm_neg_associations, learningRate / num_examples);
    if (verbose) dumpMat<float>("pmWeights.after ", "%5.1f", pmWeights);

    // error = np.sum((data - neg_visible_probs) ** 2)
    pmData.sumOfErrorSquared(pm_neg_visible_probs);
    fprintf(stderr, "completed epoch %d\n", epoch);
    timerdevice->stopTimer();
  }
  uint64_t total_cycles = lap_timer(0);
  uint64_t beats = dma->show_mem_stats(ChannelType_Read);
  fprintf(stderr, "total_cycles=%zd beats=%zd utilization=%f\n", total_cycles, beats, (float)beats / (float)total_cycles);
}

void RBM::run()
{
  int numVisible = 6;
  int numHidden = 2;
  cv::Mat trainingData = (cv::Mat_<float>(6,6) <<
			  1,1,1,0,0,0,
			  1,0,1,0,0,0,
			  1,1,1,0,0,0,
			  0,0,1,1,1,0,
			  0,0,1,1,0,0,
			  0,0,1,1,1,0);

  if (1) {
    MnistImageFile imagefile("../datasets/train-images-idx3-ubyte");
    imagefile.open();
    int numImages = imagefile.numEntries();


    numImages = 100;
    int cols = 10;
    int numPixels = imagefile.rows()*imagefile.cols();
    if (numPixels < cols)
      cols = numPixels;

    //numVisible = imagefile.rows()*imagefile.cols();
    numVisible = cols;
    numHidden = numVisible / 2;

    trainingData.create(numImages, cols, CV_32F);

    for (int i = 0; i < numImages; i++) {
      fprintf(stderr, "Reading mat %d\n", i);
      cv::Mat m = imagefile.mat(i);
      for (int j = 0; j < imagefile.rows(); j++) {
	for (int k = 0; k < imagefile.cols(); k++) {
	  int offset = j*imagefile.cols() + k;
	  if (offset < cols) {
	    trainingData.at<float>(i, offset) = (float)m.at<unsigned char>(k,j);
	  }
	}
      }
    }

  }

  train(numVisible, numHidden, trainingData);
  fprintf(stderr, "trainingData.rows=%d trainingData.cols=%d\n", trainingData.rows, trainingData.cols);
}
