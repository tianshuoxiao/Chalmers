/*
 * Copyright (C) 2018 Ola Benderius
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

#include "behavior.hpp"

Behavior::Behavior() noexcept:
  m_frontUltrasonicReading{},
  m_rearUltrasonicReading{},
  m_leftIrReading{},
  m_rightIrReading{},
  m_groundSteeringAngleRequest{},
  m_pedalPositionRequest{},
  m_axleAngularVelocityRequestLeft{}, //
  m_axleAngularVelocityRequestRight{}, //
  m_frontUltrasonicReadingMutex{},
  m_rearUltrasonicReadingMutex{},
  m_leftIrReadingMutex{},
  m_rightIrReadingMutex{},
  m_groundSteeringAngleRequestMutex{},
  m_pedalPositionRequestMutex{},
  m_axleAngularVelocityRequestLeftMutex{}, //
  m_axleAngularVelocityRequestRightMutex{} //
  
{
}

opendlv::proxy::GroundSteeringRequest Behavior::getGroundSteeringAngle() noexcept
{
  std::lock_guard<std::mutex> lock(m_groundSteeringAngleRequestMutex);
  return m_groundSteeringAngleRequest;
}

opendlv::proxy::PedalPositionRequest Behavior::getPedalPositionRequest() noexcept
{
  std::lock_guard<std::mutex> lock(m_pedalPositionRequestMutex);
  return m_pedalPositionRequest;
}

opendlv::proxy::AxleAngularVelocityRequest Behavior::getLeftAxleAngularVelocityRequest() noexcept
{
  std::lock_guard<std::mutex> lock(m_axleAngularVelocityRequestLeftMutex);
  return m_axleAngularVelocityRequestLeft;
} //left

opendlv::proxy::AxleAngularVelocityRequest Behavior::getRightAxleAngularVelocityRequest() noexcept
{
  std::lock_guard<std::mutex> lock(m_axleAngularVelocityRequestRightMutex);
  return m_axleAngularVelocityRequestRight;
} //right

void Behavior::setFrontUltrasonic(opendlv::proxy::DistanceReading const &frontUltrasonicReading) noexcept
{
  std::lock_guard<std::mutex> lock(m_frontUltrasonicReadingMutex);
  m_frontUltrasonicReading = frontUltrasonicReading;
}

void Behavior::setRearUltrasonic(opendlv::proxy::DistanceReading const &rearUltrasonicReading) noexcept
{
  std::lock_guard<std::mutex> lock(m_rearUltrasonicReadingMutex);
  m_rearUltrasonicReading = rearUltrasonicReading;
}

void Behavior::setLeftIr(opendlv::proxy::DistanceReading const &leftIrReading) noexcept
{
  std::lock_guard<std::mutex> lock(m_leftIrReadingMutex);
  m_leftIrReading = leftIrReading;
}

void Behavior::setRightIr(opendlv::proxy::DistanceReading const &rightIrReading) noexcept
{
  std::lock_guard<std::mutex> lock(m_rightIrReadingMutex);
  m_rightIrReading = rightIrReading;
}


void Behavior::step(float total_dt) noexcept //new
{
  opendlv::proxy::DistanceReading frontUltrasonicReading;
  opendlv::proxy::DistanceReading rearUltrasonicReading;
  opendlv::proxy::DistanceReading leftIrReading;
  opendlv::proxy::DistanceReading rightIrReading;
  {
    std::lock_guard<std::mutex> lock1(m_frontUltrasonicReadingMutex);
    std::lock_guard<std::mutex> lock2(m_rearUltrasonicReadingMutex);
    std::lock_guard<std::mutex> lock3(m_leftIrReadingMutex);
    std::lock_guard<std::mutex> lock4(m_rightIrReadingMutex);

    frontUltrasonicReading = m_frontUltrasonicReading;
    rearUltrasonicReading = m_rearUltrasonicReading;
    leftIrReading = m_leftIrReading;
    rightIrReading = m_rightIrReading;
  }

  float frontDistance = frontUltrasonicReading.distance();
  float rearDistance = rearUltrasonicReading.distance();
  double leftDistance = leftIrReading.distance();
  double rightDistance = rightIrReading.distance();

  float pedalPosition = 0.2f;
  float groundSteeringAngle = 0.3f;
  if (frontDistance < 0.3f) {
    pedalPosition = 0.0f;
  } else {
    if (rearDistance < 0.3f) {
      pedalPosition = 0.4f;
    }
  }

  if (leftDistance < rightDistance) {
    if (leftDistance < 0.2f) {
      groundSteeringAngle = 0.2f;
    }
  } else {
    if (rightDistance < 0.2f) {
      groundSteeringAngle = 0.2f;
    }
  }
  
 

  {
    std::lock_guard<std::mutex> lock1(m_groundSteeringAngleRequestMutex);
    std::lock_guard<std::mutex> lock2(m_pedalPositionRequestMutex);

    opendlv::proxy::GroundSteeringRequest groundSteeringAngleRequest;
    groundSteeringAngleRequest.groundSteering(groundSteeringAngle);
    m_groundSteeringAngleRequest = groundSteeringAngleRequest;

    opendlv::proxy::PedalPositionRequest pedalPositionRequest;
    pedalPositionRequest.position(pedalPosition);
    m_pedalPositionRequest = pedalPositionRequest;
  }
  
  //new
  float t1 = 3.0f;
  float t2 = 10.0f;
  float v0 = 0.5f;
  float radius = 0.04f;
  float axleAngularLeft = 0.0f;
  float axleAngularRight = 0.0f;
  if (total_dt >= 0 && total_dt <= 3){
  	axleAngularLeft = 0.0f;
  	axleAngularRight = v0*(total_dt/t1)/radius;
  } else if (total_dt > 3 && total_dt <= 10){
			axleAngularLeft = v0*((total_dt - t1)/t2)/radius;
			axleAngularRight = v0/radius;
	}	else { 
			axleAngularLeft = 0.0f;
			axleAngularRight = 0.0f;
	}
	
	  {
    std::lock_guard<std::mutex> lock3(m_axleAngularVelocityRequestLeftMutex);
    std::lock_guard<std::mutex> lock4(m_axleAngularVelocityRequestRightMutex);

    opendlv::proxy::AxleAngularVelocityRequest AxleAngularVelocityRequestLeft;
    AxleAngularVelocityRequestLeft.axleAngularVelocity(axleAngularLeft);
    m_axleAngularVelocityRequestLeft = AxleAngularVelocityRequestLeft;

    opendlv::proxy::AxleAngularVelocityRequest AxleAngularVelocityRequestRight;
    AxleAngularVelocityRequestRight.axleAngularVelocity(axleAngularRight);
    m_axleAngularVelocityRequestRight = AxleAngularVelocityRequestRight;
  }
}
