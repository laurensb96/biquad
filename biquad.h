/*
 * biquad.h
 *
 *  Created on: 25 jan. 2017
 *      Author: Laurens
 */

#ifndef BIQUAD_H_
#define BIQUAD_H_

#include <stdint.h>

enum biquad_type
{
    BIQUAD_LOPASS = 0,
    BIQUAD_HIPASS,
    BIQUAD_PK
};

struct biquad_param
{
    int32_t b0, b1, b2, a1, a2;
    int32_t prev_input[2];
    int32_t prev_output[2];
    int32_t error;
};

typedef struct biquad_param biquad_param;

void biquad_init(unsigned fs, unsigned f0, float Q_fl, biquad_param* bqp, enum biquad_type type);
int32_t biquad_apply(int32_t input, biquad_param* bqp);

int32_t float_to_fixed32(float x, int y);
float fixed32_to_float(int32_t x, int y);

#endif /* BIQUAD_H_ */
