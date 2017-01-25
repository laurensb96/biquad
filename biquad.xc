/*
 * biquad.xc
 *
 *  Created on: 25 jan. 2017
 *      Author: Laurens
 */

#include <biquad.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

// Let's use fixed-point 4.28 arithmetic
#define FBITS 28

void biquad_init(unsigned fs, unsigned f0, float Q_fl, biquad_param* bqp, enum biquad_type type)
{
    float w0 = 2 * M_PI * ((float) f0)/((float) fs);
    int32_t cos_w0 = float_to_fixed32(cos(w0), 28);
    int32_t sin_w0 = float_to_fixed32(sin(w0), 28);
    int32_t Q = float_to_fixed32(Q_fl, 28);
    int32_t alpha = (int32_t) (((int64_t) sin_w0 * (1 << FBITS))/((int64_t) 2*Q));

    int32_t b0, b1, b2, a0, a1, a2;

    switch(type)
    {
    case BIQUAD_LOPASS:
        b0 = ((1 << FBITS) - cos_w0)/2;
        b1 = (1 << FBITS) - cos_w0;
        b2 = b0;
        a0 = (1 << FBITS) + alpha;
        a1 = -2*cos_w0;
        a2 = (1 << FBITS) - alpha;
        break;
    case BIQUAD_HIPASS:
        b0 = ((1 << FBITS) + cos_w0)/2;
        b1 = (1 << FBITS) + cos_w0;
        b2 = b0;
        a0 = (1 << FBITS) + alpha;
        a1 = -2*cos_w0;
        a2 = (1 << FBITS) - alpha;
        break;
    case BIQUAD_PK:
        b0 = (1 << FBITS) + alpha;
        b1 = -2*cos_w0;
        b2 = (1 << FBITS) - alpha;
        a0 = (1 << FBITS) + alpha;
        a1 = -2*cos_w0;
        a2 = (1 << FBITS) - alpha;
        break;
    default:
        break;
    }

    b0 = (int32_t) (((int64_t) b0 * (1 << FBITS))/((int64_t) a0));
    b1 = (int32_t) (((int64_t) b1 * (1 << FBITS))/((int64_t) a0));
    b2 = (int32_t) (((int64_t) b2 * (1 << FBITS))/((int64_t) a0));
    a1 = (int32_t) (((int64_t) a1 * (1 << FBITS))/((int64_t) a0));
    a2 = (int32_t) (((int64_t) a2 * (1 << FBITS))/((int64_t) a0));

    bqp->b0 = b0;
    bqp->b1 = b1;
    bqp->b2 = b2;
    bqp->a1 = a1;
    bqp->a2 = a2;

    // Debug readout
    /*printf("%d\t%d\n", cos_w0, sin_w0);
    printf("%d\t%f\n", Q, fixed32_to_float(Q, 28));
    printf("b0: %f\t b1: %f\t b2: %f\n", fixed32_to_float(b0, 28), fixed32_to_float(b1, 28), fixed32_to_float(b2, 28));
    printf("a0: %f\t a1: %f\t a2: %f\n", fixed32_to_float(a0, 28), fixed32_to_float(a1, 28), fixed32_to_float(a2, 28));*/
}

int32_t biquad_apply(int32_t input, biquad_param* bqp)
{
    int64_t output_zeros, output_poles, output, output_scaled;

    output_zeros = (int64_t) bqp->b0 * input + bqp->b1 * bqp->prev_input[0] + bqp->b2 * bqp->prev_input[1];
    output_poles = (int64_t) bqp->a1 * bqp->prev_output[0] + bqp->a2 * bqp->prev_output[1];
    output = output_zeros - output_poles + bqp->error;
    output_scaled = (output >> FBITS);

    if(output_scaled > INT32_MAX)
        output_scaled = INT32_MAX;
    if(output_scaled < INT32_MIN)
        output_scaled = INT32_MIN;

    bqp->error = output - (output_scaled << FBITS);
    bqp->prev_input[1] = bqp->prev_input[0];
    bqp->prev_input[0] = input;
    bqp->prev_output[1] = bqp->prev_output[1];
    bqp->prev_output[0] = (int32_t) output;

    return (int32_t) output;
}

int32_t float_to_fixed32(float x, int y)
{
    int32_t z;

    z = (int32_t) (x * (float) (1 << y));

    return z;
}

float fixed32_to_float(int32_t x, int y)
{
    float z;

    z = (float) (x / (float) (1 << y));

    return z;
}
