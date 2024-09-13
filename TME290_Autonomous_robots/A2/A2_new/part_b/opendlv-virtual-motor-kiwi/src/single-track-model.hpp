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

#ifndef SINGLE_TRACK_MODEL
#define SINGLE_TRACK_MODEL

#include <mutex>

#include "opendlv-standard-message-set.hpp"

class SingleTrackModel {
 private:
  SingleTrackModel(SingleTrackModel const &) = delete;
  SingleTrackModel(SingleTrackModel &&) = delete;
  SingleTrackModel &operator=(SingleTrackModel const &) = delete;
  SingleTrackModel &operator=(SingleTrackModel &&) = delete;

 public:
  SingleTrackModel() noexcept;
  ~SingleTrackModel() = default;

 public:
 	void setLeftAngularVelocity(opendlv::proxy::AxleAngularVelocityRequest const &) noexcept;//x angle velocity
 	void setRightAngularVelocity(opendlv::proxy::AxleAngularVelocityRequest const &) noexcept;//y angle velocity
  //void setGroundSteeringAngle(opendlv::proxy::GroundSteeringRequest const &) noexcept;
  //void setPedalPosition(opendlv::proxy::PedalPositionRequest const &) noexcept;
  opendlv::sim::KinematicState step(double) noexcept;

 private:
 	std::mutex m_LeftAngularVelocityMutex;// axle angular left 
 	std::mutex m_RightAngularVelocityMutex;// axle angular right
  //std::mutex m_groundSteeringAngleMutex;
  //std::mutex m_pedalPositionMutex;
  //double m_longitudinalSpeed;
  //double m_lateralSpeed;
  //float m_groundSteeringAngle;
  //float m_pedalPosition;
  float m_leftangleV; // left
  float m_rightangleV;// right
  double m_yawRate; //
  double m_yawAngle; //
  double m_longitudinalSpeed;
  double m_lateralSpeed;
};

#endif
