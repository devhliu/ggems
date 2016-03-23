// GGEMS Copyright (C) 2015

/*!
 * \file vox_phan_iort_nav.cuh
 * \brief
 * \author J. Bert <bert.jul@gmail.com>
 * \version 0.1
 * \date 23/03/2016
 *
 *
 *
 */

#ifndef VOX_PHAN_IORT_NAV_CUH
#define VOX_PHAN_IORT_NAV_CUH

#include "ggems.cuh"
#include "global.cuh"
#include "ggems_phantom.cuh"
#include "voxelized.cuh"
#include "raytracing.cuh"
#include "vector.cuh"
#include "materials.cuh"
#include "photon.cuh"
#include "photon_navigator.cuh"
#include "image_reader.cuh"
#include "dose_calculator.cuh"
#include "electron.cuh"
#include "cross_sections.cuh"
#include "electron_navigator.cuh"
#include "transport_navigator.cuh"

// VoxPhanIORTNav -> VPIN
namespace VPIORTN
{

__host__ __device__ void track_to_out(ParticlesData &particles,
                                      VoxVolumeData vol, MaterialsTable materials,
                                      PhotonCrossSectionTable photon_CS_table,
                                      GlobalSimulationParametersData parameters, DoseData dosi, ui32 part_id);

__global__ void kernel_device_track_to_in (ParticlesData particles, f32 xmin, f32 xmax,
                                            f32 ymin, f32 ymax, f32 zmin, f32 zmax , f32 tolerance);

__global__ void kernel_device_track_to_out ( ParticlesData particles,
                                             VoxVolumeData vol,
                                             MaterialsTable materials,
                                             PhotonCrossSectionTable photon_CS_table,
                                             GlobalSimulationParametersData parameters,
                                             DoseData dosi );

void kernel_host_track_to_in (ParticlesData particles, f32 xmin, f32 xmax,
                               f32 ymin, f32 ymax, f32 zmin, f32 zmax, f32 tolerance, ui32 part_id );

void kernel_host_track_to_out ( ParticlesData particles,
                                VoxVolumeData vol,
                                MaterialsTable materials,
                                PhotonCrossSectionTable photon_CS_table,
                                GlobalSimulationParametersData parameters,
                                DoseData dosi,
                                ui32 id );
}

class VoxPhanIORTNav : public GGEMSPhantom
{
public:
    VoxPhanIORTNav();
    ~VoxPhanIORTNav() {}

    // Init
    void initialize( GlobalSimulationParameters params );
    // Tracking from outside to the phantom border
    void track_to_in( Particles particles );
    // Tracking inside the phantom until the phantom border
    void track_to_out( Particles particles );

    void load_phantom_from_mhd ( std::string filename, std::string range_mat_name );

    void calculate_dose_to_phantom();
    void calculate_dose_to_water();
    
    void write( std::string filename = "dosimetry.mhd" );
    void set_materials( std::string filename );
    void set_doxel_size( f32 sizex, f32 sizey, f32 sizez );
    void set_volume_of_interest( f32 xmin, f32 xmax, f32 ymin, f32 ymax, f32 zmin, f32 zmax );

    void export_density_map( std::string filename );
    void export_materials_map( std::string filename );

private:

    VoxelizedPhantom m_phantom;
    Materials m_materials;
    CrossSections m_cross_sections;
    DoseCalculator m_dose_calculator;

    bool m_check_mandatory();

    // Get the memory usage
    ui64 m_get_memory_usage();

    f32 m_doxel_size_x, m_doxel_size_y, m_doxel_size_z;
    f32 m_xmin, m_xmax, m_ymin, m_ymax, m_zmin, m_zmax;

    GlobalSimulationParameters m_params;

    std::string m_materials_filename;

//
};

#endif
