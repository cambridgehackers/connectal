// Copyright (c) 2012 Nokia, Inc.
// Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

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
#include "portal.h"

#define MAX_TIMER_COUNT      16

typedef struct {
    uint64_t total, min, max, over;
} PORTAL_TIMETYPE;

static uint64_t c_start[MAX_TIMER_COUNT];
static uint64_t lap_timer_temp;
static PORTAL_TIMETYPE timers[MAX_TIMERS];

uint64_t portalCycleCount()
{
    uint64_t high_bits, low_bits;
    volatile unsigned int *msb, *lsb;
    initPortalHardware();
    if(!utility_portal)
        return 0;
    msb = &utility_portal->map_base[PORTAL_CTRL_COUNTER_MSB];
    lsb = &utility_portal->map_base[PORTAL_CTRL_COUNTER_LSB];
    high_bits = utility_portal->transport->read(utility_portal, &msb);
    low_bits = utility_portal->transport->read(utility_portal, &lsb);
    return (high_bits << 32) | low_bits;
}

void portalTimerStart(unsigned int i) 
{
    if (i < MAX_TIMER_COUNT)
        c_start[i] = portalCycleCount();
}

uint64_t portalTimerLap(unsigned int i)
{
    uint64_t temp = portalCycleCount();
    if (i >= MAX_TIMER_COUNT)
        return 0;
    lap_timer_temp = temp;
    return temp - c_start[i];
}

void portalTimerInit(void)
{
    int i;
    memset(timers, 0, sizeof(timers));
    for (i = 0; i < MAX_TIMERS; i++)
      timers[i].min = 1LLU << 63;
}

uint64_t portalTimerCatch(unsigned int i)
{
    uint64_t val = portalTimerLap(0);
    if (i >= MAX_TIMERS)
        return 0;
    if (val > timers[i].max)
        timers[i].max = val;
    if (val < timers[i].min)
        timers[i].min = val;
    if (val == 000000)
        timers[i].over++;
    timers[i].total += val;
    return lap_timer_temp;
}

void portalTimerPrint(int loops)
{
    int i;
    for (i = 0; i < MAX_TIMERS; i++) {
      if (timers[i].min != (1LLU << 63))
           PORTAL_PRINTF("[%d]: avg %" PRIx64 " min %" PRIx64 " max %" PRIx64 " over %" PRIx64 "\n",
               i, timers[i].total/loops, timers[i].min, timers[i].max, timers[i].over);
    }
}

