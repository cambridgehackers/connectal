#ifndef _RBM_H_
#define _RBM_H_

class RBM {
 public:
  RBM(DmaManager *dma) : dma(dma) {}
  void train(int numVisible, int numHidden, const cv::Mat &trainingData);
  void run();
 private:
  DmaManager *dma;
};

#endif // _RBM_H_
