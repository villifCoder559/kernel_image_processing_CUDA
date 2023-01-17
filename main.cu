#include "convolution_cpu.h"
#include "convolution_gpu.h"
#include "padding_image.h"
#include <iostream>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <vector>
/*
  1) Create kernel that uses shared memory OK
  2) Manage data with size greater than constant memory OK
  2.1) Manage the case where the image is too big (DIM=500) OK
  3) Adapt algorithm to non-squared images OK
  4) Create more filters OK
  4.1) Manage the case where the product exceeds 255 OK
  5) Create classes OK
  6) Fix apply_convolution passing all class Image OK
  7) Add const to some params OK
  8) Test all OK
  9) Add pixel replication and pixel mirroring in conv_base and constant memory OK
  10) Add replication and mirroring in conv_shared_memory OK
  10.1) Clean the code (apply base and constant convolution)
  11) test new features
  END) Measure divergence and general performance (profiling) OK
*/
void compare_result(Image *cmp1, Image *cmp2);
void print_image(Image *img, std::string title = "");
void test_all_convolutions(int tot_tests, int tot_kernels, int *width, int *height, type_kernel *kernels,type_padding padding);

int main() {
  int tot_tests = 4;
  int tot_kernels = 3;
  int width[] = {1280, 1920, 2560, 8120};
  int height[] = {720, 1080, 1440, 4568};
  type_kernel kernels[] = {gaussian_blur_3x3, gaussian_blur_5x5, gaussian_blur_7x7};
  type_padding paddings[] = {zero, pixel_mirroring, pixel_replication};
  test_all_convolutions(tot_tests, tot_kernels, width, height, kernels,paddings[0]);
  // Image *img = new Image(10, 6, 100);
  // Kernel *mask = new Kernel(kernels[1]);
  // Image *result_img_base = ConvolutionGPU::apply_convolution_constant_memory(img, mask,pixel_mirroring);
  // print_image(result_img_base);
}

void test_all_convolutions(int tot_tests, int tot_kernels, int *width, int *height, type_kernel *kernels,type_padding padding) {
  for (int i = 0; i < tot_tests; i++) {
    Image *img = new Image(width[i], height[i], 100);
    for (int j = 0; j < tot_kernels; j++) {
      Kernel *mask = new Kernel(kernels[j]);
      printf("\n(%d,%d) using %dx%d gaussian filter \n", width[i], height[i], mask->get_size(), mask->get_size());
      Image *result_img_base = ConvolutionGPU::apply_convolution_global_memory(img, mask);
      Image *result_img_constant = ConvolutionGPU::apply_convolution_constant_memory(img, mask,padding);
      Image *result_img_shared = ConvolutionGPU::apply_convolution_shared_memory(img, mask,padding);
      // Image *result_cpu_seq = ConvolutionCPU::apply_convolution_sequential(img, mask,padding);
      // Image *result_cpu_par = ConvolutionCPU::apply_convolution_parallel(img, mask,padding);
      compare_result(result_img_base, result_img_shared);
      compare_result(result_img_shared, result_img_constant);
      // compare_result(result_img_base, result_cpu_seq);
      // compare_result(result_cpu_seq, result_cpu_par);
      delete mask;
      delete result_img_base;
      delete result_img_constant;
      delete result_img_shared;
      // delete result_cpu_seq;
      // delete result_cpu_par;
    }
    delete img;
    printf("\n");
  }
}
void compare_result(Image *cmp1, Image *cmp2) {
  if (cmp1->get_height() == cmp2->get_height() && cmp1->get_width() == cmp2->get_width()) {
    int width = cmp1->get_width();
    for (int i = 0; i < cmp1->get_height(); i++) {
      for (int j = 0; j < cmp1->get_width(); j++)
        if ((cmp1->get_image())[i * width + j] != (cmp2->get_image())[i * width + j])
          printf("%d!=%d \t", cmp1->get_image()[i * width + j], cmp2->get_image()[i * width + j]);
    }
  } else
    printf("Sizes not equal");
}
void print_image(Image *img, std::string title) {
  int width = img->get_width();
  std::cout << title << std::endl;
  for (int i = 0; i < img->get_height(); i++) {
    for (int j = 0; j < img->get_width(); j++)
      printf("%d \t", (img->get_image())[i * width + j]);
    printf("\n");
  }
}
