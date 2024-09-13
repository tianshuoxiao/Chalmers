#include <iostream>
#include <chrono>

#include "cluon-complete.hpp"
#include "messages.hpp"

int32_t main(int32_t, char** ) {


  // Create an OD4Session object with the specified conference ID.
  cluon::OD4Session od4(132, 
    [&od4](cluon::data::Envelope &&envelope) noexcept {
      if (envelope.dataType() == 1091) {
        opendlv::proxy::GroundSpeedRequest requestMsg = cluon::extractMessage<opendlv::proxy::GroundSpeedRequest>(std::move(envelope));

        // Calculate the ground speed reading based on the request message and multiply factor.
        float groundSpeedReading = requestMsg.groundSpeed() * 2.5;

        // Create a GroundSpeedReading message with the calculated ground speed reading.
        opendlv::proxy::GroundSpeedReading readingMsg;
        readingMsg.groundSpeed(groundSpeedReading);
        std::cout << "Sendback message: " << readingMsg.groundSpeed() << std::endl;
        // Send the GroundSpeedReading message on the same conference ID.
        od4.send(readingMsg);
    }
  });
  
    

  // Keep the program running until a SIGINT signal is received.
  while (od4.isRunning()) {
    // Wait for the GroundSpeedReading message to be received and output it.
    cluon::OD4Session od4(132, 
      [] (cluon::data::Envelope &&envelope) noexcept { 
        if (envelope.dataType() == 1046) {     
          opendlv::proxy::GroundSpeedReading readingMsg = cluon::extractMessage<opendlv::proxy::GroundSpeedReading>(std::move(envelope));
          
          std::cout << "Received ground speed reading: " << readingMsg.groundSpeed() << std::endl;
          
      
    };
  });

    // Get the user input.
    std::cout << "Enter a number to request ground speed:" << std::endl;
    float groundSpeedRequest;
    std::cin >> groundSpeedRequest; 

    // Create a GroundSpeedRequest message with the user input.
    opendlv::proxy::GroundSpeedRequest requestMsg1;
    requestMsg1.groundSpeed(groundSpeedRequest);
    
    // Send the GroundSpeedRequest message on the conference ID.
    od4.send(requestMsg1);
    

  
 }
 return 0;
}
