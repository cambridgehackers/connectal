/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "SinkIndication.h"
#include "SinkRequest.h"
#include "GeneratedTypes.h"

#include <stdio.h>
#include <stdlib.h>

pthread_mutex_t count_mutex     = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t  condition_var   = PTHREAD_COND_INITIALIZER;
int count = 0;

class SinkIndication : public SinkIndicationWrapper
{
public:
  virtual void returnTokens(uint32_t v) {
    // Lock mutex and update the count variable
    pthread_mutex_lock( &count_mutex );
    count += v;

    // Signal to main() thread that more tokens have been
    // returned from the SinkRequest hardware and unlock mutex
    pthread_cond_signal( &condition_var );
    pthread_mutex_unlock( &count_mutex );
  }
  SinkIndication(unsigned int id) : SinkIndicationWrapper(id){}
};

int main(int argc, const char **argv)
{

  int tokens = 0;
  SinkIndication *sinkIndication = new SinkIndication(IfcNames_SinkIndication);
  SinkRequestProxy *sinkRequestProxy = new SinkRequestProxy(IfcNames_SinkRequest);
  
  fprintf(stderr, "Main::creating exec thread\n");
  sinkRequestProxy->init(0);
  while(tokens < 32){

    // Lock mutex and then wait for signal to relase mutex
    pthread_mutex_lock( &count_mutex );

    // Wait while SinkIndication::returnTokens updates count
    // mutex unlocked if condition varialbe is signaled.
    pthread_cond_wait( &condition_var, &count_mutex );

    // consume the credit
    int local_count = count;
    count = 0;

    // Unlock the mutex so SinkIndication::returnTokens can
    // accept more tokens from the SinkRequest hardware
    pthread_mutex_unlock( &count_mutex );

    while(local_count){
      fprintf(stderr, "main() count:%d\n", local_count--);
      sinkRequestProxy->put(tokens++);
    }

  }
  
  return 0;
}
