/*
 * Copyright (C) 2022 Ola Benderius
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "cluon-complete.hpp"
#include "opendlv-standard-message-set.hpp"

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>

#include <cstdint>
#include <iostream>
#include <memory>
#include <vector>
#include <mutex>

using namespace cv;

int32_t main(int32_t, char **) {

  // Use libcluon/OpenDLV to attach to the shared memory.
  std::string const shmName = "video0.argb";
  std::unique_ptr<cluon::SharedMemory> shm(new cluon::SharedMemory(shmName));
  
  if (shm == nullptr || !shm->valid()) {
    std::cerr << "Could not connect to shared memory '" << shmName
      << "'. Is the data replay running?" << std::endl;
    return -1;
  }

  // Use libcluon/OpenDLV to attach to UDP multicast session.
  uint16_t cid = 111;
  cluon::OD4Session od4(cid);

  // Handler to receive speed readings (realized as C++ lambda).
  std::mutex speedMutex;
  float speedUnsafe{0};
  auto onSpeed = [&speedMutex, &speedUnsafe](cluon::data::Envelope &&env){
    // Now, we unpack the cluon::data::Envelope to get the
    // desired GroundSpeedReading.
    opendlv::proxy::GroundSpeedReading gsr
      = cluon::extractMessage<opendlv::proxy::GroundSpeedReading>(
          std::move(env));

    // Store speed reading.
    std::lock_guard<std::mutex> lck(speedMutex);
    speedUnsafe = gsr.groundSpeed();
  };

  // Finally, we register our lambda for the message identifier for
  // opendlv::proxy::GroundSpeedReading.
  od4.dataTrigger(opendlv::proxy::GroundSpeedReading::ID(), onSpeed);


  // Endless loop; end the program by pressing Ctrl-C.
  uint32_t imgWidth = 640;
  uint32_t imgHeight = 480;
  while (od4.isRunning()) {

    //// Copy speed from unsafe variable (thread-safety)
    float speed;
    {
      std::lock_guard<std::mutex> lck(speedMutex);
      speed = speedUnsafe;
    }
    std::cout << "speed = " << speed << std::endl;


    //// Read an image from shared memory into local memory.
    cv::Mat img;

    // Wait for a notification of a new frame.
    shm->wait();

    // Lock the shared memory.
    shm->lock();
    {
      // Copy image into cv::Mat structure.
      // Be aware of that any code between lock/unlock is blocking
      // the data replay to provide the next frame. Thus, any
      // computationally heavy algorithms should be placed outside
      // lock/unlock
      cv::Mat wrapped(imgHeight, imgWidth, CV_8UC4, shm->data());
      img = wrapped.clone();
    }
    shm->unlock();


    //// Examples of some OpenCV operations. You can easily find more online.
    cv::Mat img_b = img.clone(); // new image for part b
    cv::Mat img_gray = img.clone();// new gray image


    std::string speedText = "Speed: " + std::to_string(speed) + " m/s"; // speed text
    cv::putText(img, //target image
            speedText, //text
            cv::Point(10, 30), //top-left position
            cv::FONT_HERSHEY_DUPLEX, //typeface
            0.8,//type size
            CV_RGB(118, 185, 0), //font color
            1 );//font thickness

    // Draw a red rectangle
    //cv::rectangle(img, cv::Point(50, 5*speed), cv::Point(100, 10*speed), cv::Scalar(0, 0, 255));// change
    // Draw a blue circle
    cv::circle(img, cv::Point(320, 480-int(15*speed)), 15, cv::Scalar(255, 0, 0)); // circle

    //cv::imshow("Image with a rectangle", img);
    cv::imshow("Image with a blue circle", img);
    


    // Find color. First convert BGR (blue, green, red) format to HSV (hue,
    // saturation, value). Then filter out colors based on HSV ranges.
    // H=[0-179], S=[0-255], V=[0-255]. NOTE: OpenCV uses unusual H range.

    cv::rectangle(img,cv::Point(0,0),cv::Point(640,260),cv::Scalar(0,0,255),-1); //new layer
    cv::Mat hsvImg;
    
    cv::cvtColor(img, hsvImg, cv::COLOR_BGR2HSV);

    
    //cv::Scalar lowerSkyColor(0, 0, 180);   // Lower HSV threshold for sky (white color range)
    //cv::Scalar upperSkyColor(180, 30, 255); // Upper HSV threshold for sky (white color range)
    //cv::Scalar lowerRoadColor(0, 0, 180);   // Lower HSV threshold for road (white color range)
    //cv::Scalar upperRoadColor(180, 30, 255); // Upper HSV threshold for road (white color range)
    
    // Create masks for sky and road regions
    //cv::Mat skyMask, roadMask;
    //cv::inRange(hsvImg, lowerSkyColor, upperSkyColor, skyMask);
    //cv::inRange(hsvImg, lowerRoadColor, upperRoadColor, roadMask);
    
    //cv::Mat finalMask = skyMask | roadMask;
    //cv::Mat filteredImage;
    //img.copyTo(filteredImage, finalMask);

    // Display the filtered image
    //cv::imshow("Color mask", filteredImage);    
    
    cv::Mat mask;
    cv::inRange(hsvImg, cv::Scalar(0, 0, 180), cv::Scalar(180, 35, 255), mask);
/*   
    std::vector< std::vector < cv::Point >> contours;//new
    cv::findContours(mask,contours,CV_RETR_EXTERNAL,CV_CHAIN_APPROX_NONE);
    std::cout <<"contours.size()=" << contours.size() << std::endl;


    cv::drawContours(img_b,contours,-1,cv::Scalar(0),3); //draw
    for (const auto& contour : contours) {
        
        cv::Moments moments = Moments(contour);
        if (moments.m00 != 0){
        Point center(static_cast<int>(moments.m10 / moments.m00),
                     static_cast<int>(moments.m01 / moments.m00));

        

        circle(img_b, center, 5, Scalar(0, 0, 255), -1);
        }
    }
*/ 
    // Display color mask.
    cv::imshow("Image with color mask", mask);
    //cv::imshow("drawimg",img_b); //new



    // For the OpenCV GUI.
    cv::waitKey(1);
  }
  
  return 0;
}
