/*
 * Copyright (c) 2007 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date July 24, 2007
 */
 
#include "printf.h"
#include "SensingConstants.h"
module SensingBaseC {
  uses {
    interface Boot;
    interface Queue<serial_sample_msg_t> as SampleQueue;
    interface Leds;

    interface SplitControl as SerialAMControl;
    interface AMPacket as SerialAMPacket;
    interface Packet as SerialPacket;

    interface SplitControl as RadioAMControl;
    interface AMPacket as RadioAMPacket;
    interface Packet as RadioPacket;

    interface Receive as SerialRequestSampleMsgsReceive;
    interface AMSend as RadioRequestSampleMsgsSend;
    interface Receive as RadioSampleMsgReceive;
    interface AMSend as SerialSampleMsgSend;
  }
}
implementation {
  bool serialSending;
  message_t request_samples_msg;
  message_t sample_msg;
  serial_sample_msg_t* sample_msg_payload;

  void printSampleLine(serial_sample_msg_t* serial_sample) {
    printf("ID=%u Count=%lu Temp=%u Humidity=%u Photo=%u Solar=%u\n",
      (uint16_t)serial_sample->src_addr,
      (unsigned long)serial_sample->sample.sample_num,
      (uint16_t)serial_sample->sample.temperature,
      (uint16_t)serial_sample->sample.humidity,
      (uint16_t)serial_sample->sample.photo_active,
      (uint16_t)serial_sample->sample.total_solar);
    printfflush();
  }

  void sendSerialSample(serial_sample_msg_t* serial_sample) {
    sample_msg_payload->src_addr = serial_sample->src_addr;
    sample_msg_payload->sample = serial_sample->sample;
    serialSending = TRUE;
    if(call SerialSampleMsgSend.send(AM_BROADCAST_ADDR, &sample_msg, sizeof(serial_sample_msg_t)) != SUCCESS)
      serialSending = FALSE;
  }

  event void Boot.booted() {
    serialSending = FALSE;
    sample_msg_payload = (serial_sample_msg_t*)call SerialPacket.getPayload(&sample_msg, sizeof(serial_sample_msg_t));
    call RadioAMControl.start();
  }
  
  event void RadioAMControl.startDone(error_t error) {
    call SerialAMControl.start();
  }

  event void SerialAMControl.startDone(error_t error) {
  }

  event void RadioAMControl.stopDone(error_t error) {
  }

  event void SerialAMControl.stopDone(error_t error) {
  }

  event message_t* SerialRequestSampleMsgsReceive.receive(message_t* msg, void* payload, uint8_t len) {
    serial_request_samples_msg_t* request_msg = payload;
    call Leds.led0On();
    call RadioRequestSampleMsgsSend.send(request_msg->addr, &request_samples_msg, sizeof(request_samples_msg_t));
    return msg;
  }

  event void RadioRequestSampleMsgsSend.sendDone(message_t* msg, error_t error) {
    if(error == SUCCESS)
      call Leds.led0Off();
  }

  event message_t* RadioSampleMsgReceive.receive(message_t* msg, void* payload, uint8_t len) {
    serial_sample_msg_t serial_sample;
    nx_sensor_sample_t* radio_sample = payload;

    if(len != sizeof(nx_sensor_sample_t))
      return msg;

    call Leds.led2Toggle();
    serial_sample.src_addr = call RadioAMPacket.source(msg);
    serial_sample.sample = *radio_sample;

    printSampleLine(&serial_sample);

    if(call SampleQueue.empty() == FALSE || serialSending == TRUE) {
      if(call SampleQueue.enqueue(serial_sample) != SUCCESS)
        call Leds.led1Toggle();
    }
    else
      sendSerialSample(&serial_sample);

    return msg;
  }

  event void SerialSampleMsgSend.sendDone(message_t* msg, error_t error) {
    if(error != SUCCESS) {
      if(call SerialSampleMsgSend.send(AM_BROADCAST_ADDR, &sample_msg, sizeof(serial_sample_msg_t)) == SUCCESS)
        return;
    }

    if(call SampleQueue.empty() == FALSE) {
      serial_sample_msg_t serial_sample = call SampleQueue.dequeue();
      sendSerialSample(&serial_sample);
    }
    else serialSending = FALSE;
  }
}
