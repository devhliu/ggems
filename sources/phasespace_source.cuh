// GGEMS Copyright (C) 2015

/*!
 * \file phasespace_source.cuh
 * \brief Header of the phasespace source class
 * \author J. Bert <bert.jul@gmail.com>
 * \version 0.1
 * \date 15 mars 2016
 *
 * Phasespace class
 *
 * UNDER CONSTRUCTION
 *
 */

#ifndef PHASESPACE_SOURCE_CUH
#define PHASESPACE_SOURCE_CUH

#include "global.cuh"
#include "particles.cuh"
#include "ggems_source.cuh"
#include "prng.cuh"
#include "iaea_io.cuh"

struct PhSpTransform
{
    f32 tx, ty, tz;
    f32 rx, ry, rz;
    f32 sx, sy, sz;
};

class GGEMSource;

namespace PHSPSRC
{
__host__ __device__ void phsp_source( ParticlesData particles_data,
                                      IaeaType phasespace, PhSpTransform transform, ui32 id );
__global__ void phsp_point_source( ParticlesData particles_data,
                                   IaeaType phasespace, PhSpTransform transform );
}

// PhaseSpace source
class PhaseSpaceSource : public GGEMSSource
{
public:
    PhaseSpaceSource();
    ~PhaseSpaceSource();

    // Setting    
    void set_translation( f32 tx, f32 ty, f32 tz );
    void set_rotation( f32 aroundx, f32 aroundy, f32 aroundz );
    void set_scaling( f32 sx, f32 sy, f32 sz );

    // Main
    void load_phasespace_file( std::string filename );

    // Abstract from GGEMSSource (Mandatory funtions)
    void get_primaries_generator( Particles particles );
    void initialize( GlobalSimulationParameters params );

private:
    bool m_check_mandatory();

    GlobalSimulationParameters m_params;
    PhSpTransform m_transform;
    IAEAIO *m_iaea;
    IaeaType m_phasespace;

};

#endif
