#ifndef __NXTOS_SYSTICK_H__
#define __NXTOS_SYSTICK_H__

#include "mytypes.h"

void systick_init();
void systick_get_time(U32 *sec, U32 *usec);
U32 systick_get_ms();
void systick_wait_ms(U32 ms);
void systick_wait_ns(U32 n);

#endif