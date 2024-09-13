/*
 * Copyright (C) 2019 Ola Benderius
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

#include <iostream>

#include "cluon-complete.hpp"
#include "tme290-sim-grass-msg.hpp"
uint32_t pos_i;
uint32_t pos_j;
uint32_t myI;
uint32_t myJ;
float Grass_Centre;
float Battery_bot;
float map_rain;
int actions;
int findmyway;
int charge_times;
bool rt = 0;
bool wall = 0;




auto gotoChargeStation(uint32_t i, uint32_t j){
  if(j >= 18){
    if(i < 22){
      actions = 4;      
      }
    else{
        actions = 2;
      }
    }
  else{
    if(j > 0){
        actions = 2;
      } 
    else if(i > 0){
        actions = 8;
      }
    }

    if(i == 0 && j == 0){
    actions = 0;

    
  } 
  charge_times = 1;
  }


void behindwall(uint32_t i){
  if (i != 0){
    actions = 8;
  } else {
    actions = 0;
    wall = 1;
  }
}


auto gotoCut(uint32_t i, uint32_t j, float battery){

  if(j==18 && wall==0){
    behindwall(i);
  }
  else if(j%2 == 0){
    if(i == 39){
      actions = 6;
    } else {
      actions = 4;
    }
  } else if(j == 17){
    if(i == 23){
      actions = 6;
    }else{
      actions = 8;
    }
  } else {
    if(i == 0){
      actions = 6;
    }else{
      actions = 8;
    }
  }


  if(battery >= 0.4f){
    pos_i = i;
    pos_j = j;
  }
  
    
}


void cutGrass(uint32_t i, uint32_t j, float grasscentre, float battery, float Rain){

  if(grasscentre > 0.2f && Rain < 0.2f){
    actions = 0;
  } else {
    gotoCut(i, j, battery);
  }

  if(Rain > 0.2){
    actions = 0;
  }
    
}

void find(uint32_t i, uint32_t j){
  
  if (pos_i <= 21 && pos_j >= 18) {
    if (i < 22 && j < pos_j) {
        actions = 4;
    }
    else if (j < pos_j) {
        actions = 6;
    }
    else if(i > pos_i){
        actions = 8;
    }
  }
  else{
    if (i < pos_i) {
      actions = 4;
    }
    else if(j < pos_j){
      actions = 6;
    }
    
  }
  
  if(i==pos_i && j==pos_j){
    rt = 0;
    actions = 0;
  }
  
}



int32_t main(int32_t argc, char **argv) {
  int32_t retCode{0};
  auto commandlineArguments = cluon::getCommandlineArguments(argc, argv);
  if (0 == commandlineArguments.count("cid")) {
    std::cerr << argv[0] 
      << " is a lawn mower control algorithm." << std::endl;
    std::cerr << "Usage:   " << argv[0] << " --cid=<OpenDLV session>" 
      << "[--verbose]" << std::endl;
    std::cerr << "Example: " << argv[0] << " --cid=111 --verbose" << std::endl;
    retCode = 1;
  } else {
    bool const verbose{commandlineArguments.count("verbose") != 0};
    uint16_t const cid = std::stoi(commandlineArguments["cid"]);
    
    cluon::OD4Session od4{cid};

   

    auto onSensors{[&od4](cluon::data::Envelope &&envelope)
      {
        auto msg = cluon::extractMessage<tme290::grass::Sensors>(
            std::move(envelope));
            Battery_bot = msg.battery();
            myI = msg.i();
            myJ = msg.j();
            Grass_Centre = msg.grassCentre();
            map_rain = msg.rain();

            if(Battery_bot < 0.4f){
              gotoChargeStation(myI, myJ);
            } else if(Battery_bot < 1.0f && myI == 0 && myJ == 0){
              actions = 0;
            } else if(Battery_bot > 0.99f && myI == 0 && myJ == 0){
              if(charge_times == 1){
                rt = 1;
                find(myI, myJ);
              }else{
                std::cout<< "actions 4" << std::endl;
              actions = 4;
              }
            } else if((myI != 0 || myJ != 0) && Battery_bot > 0.4){
              if(rt == 1){
                std::cout << "here rt" << rt << std::endl;
                find(myI, myJ);
                
              }
              else{
               cutGrass(myI,myJ, Grass_Centre, Battery_bot, map_rain);
              }
            } 
            

        
      
        tme290::grass::Control control;
        control.command(actions);

        // After 20 steps, start pausing on every other step.
        //if (someVariable > 20 && someVariable % 2 == 0) {
        //  control.command(0);
       // } else {
        //  control.command(5);
        //}

        std::cout << "Rain reading " << msg.rain() << ", direction (" <<
         msg.rainCloudDirX() << ", " << msg.rainCloudDirY() << ")" << std::endl; 

        od4.send(control);
      }};

    auto onStatus{[&verbose](cluon::data::Envelope &&envelope)
      {
        auto msg = cluon::extractMessage<tme290::grass::Status>(
            std::move(envelope));
        if (verbose) {
          std::cout << "Status at time " << msg.time() << ": " 
            << msg.grassMean() << "/" << msg.grassMax() << std::endl;
        }
      }};

    od4.dataTrigger(tme290::grass::Sensors::ID(), onSensors);
    od4.dataTrigger(tme290::grass::Status::ID(), onStatus);

    if (verbose) {
      std::cout << "All systems ready, let's cut some grass!" << std::endl;
    }

    tme290::grass::Control control;
    control.command(0);
    od4.send(control);

    while (od4.isRunning()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(1000));
    }

    retCode = 0;
  }
  return retCode;
}







