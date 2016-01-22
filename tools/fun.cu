// GGEMS Copyright (C) 2015

/*!
 * \file fun.cu
 * \brief
 * \author J. Bert <bert.jul@gmail.com>
 * \version 0.1
 * \date 13 novembre 2015
 *
 *
 *
 */

#ifndef FUN_CU
#define FUN_CU
#include "fun.cuh"
#include "prng.cuh"



// rotateUz, function from CLHEP
__host__ __device__ f32xyz rotateUz ( f32xyz vector, f32xyz newUz )
{
    f32 u1 = newUz.x;
    f32 u2 = newUz.y;
    f32 u3 = newUz.z;
    f32 up = u1*u1 + u2*u2;

    if ( up>0 )
    {
        up = sqrtf ( up );
        f32 px = vector.x,  py = vector.y, pz = vector.z;
        vector.x = ( u1*u3*px - u2*py ) /up + u1*pz;
        vector.y = ( u2*u3*px + u1*py ) /up + u2*pz;
        vector.z =    -up*px +             u3*pz;
    }
    else if ( u3 < 0. )
    {
        vector.x = -vector.x;    // phi=0  theta=gpu_pi
        vector.z = -vector.z;
    }

    return make_f32xyz ( vector.x, vector.y, vector.z );
}

// Loglog interpolation
__host__ __device__ f32 loglog_interpolation ( f32 x, f32 x0, f32 y0, f32 x1, f32 y1 )
{
    if ( x < x0 ) return y0;
    if ( x > x1 ) return y1;
    x0 = 1.0f / x0;
    return powf ( 10.0f, log10f ( y0 ) + log10f ( y1 / y0 ) * ( log10f ( x * x0 ) / log10f ( x1 * x0 ) ) );
}

// // Binary search f32
// __host__ __device__ ui32 binary_search(f32 key, f32* tab, ui32 size, ui32 min=0) {
//     ui32 max=size, mid;
//     while ((min < max)) {
//         mid = (min + max) >> 1;
//         if (key > tab[mid]) {
//             min = mid + 1;
//         } else {
//             max = mid;
//         }
//     }
//     return min;
// }
//
// // Binary search f64
// __host__ __device__ ui32 binary_search(f64 key, f64* tab, ui32 size, ui32 min=0) {
//     ui32 max=size, mid;
//     while ((min < max)) {
//         mid = (min + max) >> 1;
//         if (key > tab[mid]) {
//             min = mid + 1;
//         } else {
//             max = mid;
//         }
//     }
//     return min;
// }

// Linear interpolation
__host__ __device__ f32 linear_interpolation ( f32 xa,f32 ya, f32 xb, f32 yb, f32 x )
{
    // Taylor young 1st order
//     if ( xa > x ) return ya;
//     if ( xb < x ) return yb;
    
    if (xa > xb) return yb;
    if (xa >= x) return ya;
    if (xb <= x) return yb;
    
    return ya + ( x-xa ) * ( yb-ya ) / ( xb-xa );
}


__host__ __device__ int G4Poisson ( f32 mean,ParticlesData &particles, int id )
{
    f32    number=0.;

    f32  position,poissonValue,poissonSum;
    f32  value,y,t;
    if ( mean<=16. ) // border == 16
    {
        do
        {
            position=JKISS32 ( particles, id );
        }
        while ( ( 1.-position ) <2.e-7 ); // to avoid 1 due to f32 approximation
        poissonValue=expf ( -mean );
        poissonSum=poissonValue;
        while ( ( poissonSum<=position ) && ( number<40000. ) )
        {
            number++;
            poissonValue*=mean/number;
            if ( ( poissonSum+poissonValue ) ==poissonSum ) break;
            poissonSum+=poissonValue;
        }

        return  ( int ) number;
    }
    f32 toto = JKISS32 ( particles, id );

    t=sqrtf ( -2.*logf ( toto ) );

    y=2.*gpu_pi*JKISS32 ( particles, id );
    t*=cosf ( y );
    value=mean+t*sqrtf ( mean ) +.5;

    if ( value<=0. )
        return  0;
    else if ( value>=2.e9 ) // f32 limit = 2.e9
        return  ( int ) 2.e9;
    return  ( int ) value;
}

__host__ __device__ f32 Gaussian ( f32 mean,f32 rms,ParticlesData &particles, int id )
{
    f32  data;
    f32  U1,U2,Disp,Fx;

    do
    {
        U1=2.*JKISS32 ( particles, id )-1.;
        U2=2.*JKISS32 ( particles, id )-1.;
        Fx=U1*U1+U2*U2;

    }
    while ( ( Fx>=1. ) );


    Fx=sqrtf ( ( -2.*logf ( Fx ) ) /Fx );
//     if(isfinite(Fx)){ printf("%d\t%f\t%f\n",id,Fx,temps); Fx = 0.5; }

    Disp=U1*Fx;
    data=mean+Disp*rms;
//     data =
//      data = Disp*rms;
//      if(isnan(data)|| isinf(data)) data =0.;
    return  data;
}

__host__ __device__ i32xyz get_bin_xyz ( i32 bin, i32xyz size )
{

    int dx = bin%size.x;
    int dy = ( ( bin - dx ) / size.x  ) %size.y;
    int dz = ( bin - dx - dy*size.x ) / ( size.x * size.y );

    return make_i32xyz ( dx,dy,dz );
}

__host__ __device__ ui32xyzw get_phantom_index( f32xyz pos, f32xyz offset, f32xyz size, ui32xyz nvoxels )
{

    f32xyz ivoxsize;
    ivoxsize.x = 1.0 / size.x;
    ivoxsize.y = 1.0 / size.y;
    ivoxsize.z = 1.0 / size.z;
    ui32xyzw index_phantom;
    index_phantom.x = ui32 ( ( pos.x-offset.x ) * ivoxsize.x );
    index_phantom.y = ui32 ( ( pos.y-offset.y ) * ivoxsize.y );
    index_phantom.z = ui32 ( ( pos.z-offset.z ) * ivoxsize.z );
    index_phantom.w = index_phantom.z*nvoxels.x*nvoxels.y
                      + index_phantom.y*nvoxels.x
                      + index_phantom.x; // linear index

    return index_phantom;
}

#endif
