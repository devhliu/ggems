// GGEMS Copyright (C) 2017

/*!
 * \file dose_calculator.cu
 * \brief
 * \author J. Bert <bert.jul@gmail.com>
 * \version 0.4
 * \date 02/12/2015
 * \date 26/02/2016, add volume of interest, change offset handling and fix many bugs - JB
 * \date 18/04/2016, change every things, use unified memory, improve code - JB
 *
 * v0.4: JB - Change all structs and remove CPU exec
 *
 */

#ifndef DOSE_CALCULATOR_CU
#define DOSE_CALCULATOR_CU

#include "dose_calculator.cuh"

/// CPU&GPU functions //////////////////////////////////////////////////////////

// Analog deposition
__host__ __device__ void dose_record_standard ( DoseData *dose, f32 Edep, f32 px, f32 py, f32 pz )
{

    if (px < dose->xmin + EPSILON3 || px > dose->xmax - EPSILON3) return;
    if (py < dose->ymin + EPSILON3 || py > dose->ymax - EPSILON3) return;
    if (pz < dose->zmin + EPSILON3 || pz > dose->zmax - EPSILON3) return;

    // Defined index phantom    
    ui32xyzw index_phantom;
    index_phantom.x = ui32 ( ( px + dose->offset.x ) * dose->inv_dosel_size.x );
    index_phantom.y = ui32 ( ( py + dose->offset.y ) * dose->inv_dosel_size.y );
    index_phantom.z = ui32 ( ( pz + dose->offset.z ) * dose->inv_dosel_size.z );
    index_phantom.w = index_phantom.z * dose->slice_nb_dosels + index_phantom.y * dose->nb_dosels.x + index_phantom.x;

    //printf("Edep %e  pos %e %e %e  index %i\n", Edep, px, py, pz, index_phantom.w);

#ifdef DEBUG

    if ( index_phantom.x >= dose->nb_dosels.x || index_phantom.y >= dose->nb_dosels.y || index_phantom.z >= dose->nb_dosels.z)
    {
        printf(" IndexX %i  NbDox %i  px %f  Off %f invDox %f\n", index_phantom.x, dose->nb_dosels.x, px, dose->offset.x, dose->inv_dosel_size.x);
        printf(" IndexY %i  NbDox %i  py %f  Off %f invDox %f\n", index_phantom.y, dose->nb_dosels.y, py, dose->offset.y, dose->inv_dosel_size.y);
        printf(" IndexZ %i  NbDox %i  pz %f  Off %f invDox %f\n", index_phantom.z, dose->nb_dosels.z, pz, dose->offset.z, dose->inv_dosel_size.z);
        //index_phantom.z = 0;
    }

    assert( index_phantom.x < dose->nb_dosels.x );
    assert( index_phantom.y < dose->nb_dosels.y );
    assert( index_phantom.z < dose->nb_dosels.z );
#endif

/*
#ifdef __CUDA_ARCH__
    atomicAdd(&dose.edep[index_phantom.w], Edep);
    atomicAdd(&dose.edep_squared[index_phantom.w], Edep*Edep);
    atomicAdd(&dose.number_of_hits[index_phantom.w], ui32(1));
#else
    dose.edep[index_phantom.w] += Edep;
    dose.edep_squared[index_phantom.w] += (Edep*Edep);
    dose.number_of_hits[index_phantom.w] += 1;
#endif
*/

    ggems_atomic_add_f64( dose->edep, index_phantom.w, f64( Edep ) );
    ggems_atomic_add_f64( dose->edep_squared, index_phantom.w, f64( Edep) * f64( Edep ) );
    ggems_atomic_add( dose->number_of_hits, index_phantom.w, ui32 ( 1 ) );                  // ui32, limited to 4.29e9 - JB


}

// TLE deposition
__host__ __device__ void dose_record_TLE( DoseData *dose, f32 Edep, f32 px, f32 py, f32 pz,
                                          f32 length, f32 mu_en)
{

    if (px < dose->xmin + EPSILON3 || px > dose->xmax - EPSILON3) return;
    if (py < dose->ymin + EPSILON3 || py > dose->ymax - EPSILON3) return;
    if (pz < dose->zmin + EPSILON3 || pz > dose->zmax - EPSILON3) return;

    // Defined index phantom
    ui32xyzw index_phantom;
    index_phantom.x = ui32 ( ( px + dose->offset.x ) * dose->inv_dosel_size.x );
    index_phantom.y = ui32 ( ( py + dose->offset.y ) * dose->inv_dosel_size.y );
    index_phantom.z = ui32 ( ( pz + dose->offset.z ) * dose->inv_dosel_size.z );
    index_phantom.w = index_phantom.z * dose->slice_nb_dosels + index_phantom.y * dose->nb_dosels.x + index_phantom.x;

#ifdef DEBUG

    if ( index_phantom.x >= dose->nb_dosels.x || index_phantom.y >= dose->nb_dosels.y || index_phantom.z >= dose->nb_dosels.z)
    {
        printf(" IndexX %i  NbDox %i  px %f  Off %f invDox %f\n", index_phantom.x, dose->nb_dosels.x, px, dose->offset.x, dose->inv_dosel_size.x);
        printf(" IndexY %i  NbDox %i  py %f  Off %f invDox %f\n", index_phantom.y, dose->nb_dosels.y, py, dose->offset.y, dose->inv_dosel_size.y);
        printf(" IndexZ %i  NbDox %i  pz %f  Off %f invDox %f\n", index_phantom.z, dose->nb_dosels.z, pz, dose->offset.z, dose->inv_dosel_size.z);
        //index_phantom.z = 0;
    }

    assert( index_phantom.x < dose->nb_dosels.x );
    assert( index_phantom.y < dose->nb_dosels.y );
    assert( index_phantom.z < dose->nb_dosels.z );
#endif

    // TLE
    f64 energy_dropped = Edep * mu_en * length * 0.1; // arbitrary factor (see in GATE)

/*
#ifdef __CUDA_ARCH__
    atomicAdd(&dose.edep[index_phantom.w], energy_dropped);
    atomicAdd(&dose.edep_squared[index_phantom.w], energy_dropped*energy_dropped);
    atomicAdd(&dose.number_of_hits[index_phantom.w], ui32(1));
#else
    dose.edep[index_phantom.w] += energy_dropped;
    dose.edep_squared[index_phantom.w] += (energy_dropped*energy_dropped);
    dose.number_of_hits[index_phantom.w] += 1;
#endif
*/

    ggems_atomic_add_f64( dose->edep, index_phantom.w, energy_dropped );
    ggems_atomic_add_f64( dose->edep_squared, index_phantom.w, energy_dropped * energy_dropped );
    ggems_atomic_add( dose->number_of_hits, index_phantom.w, ui32 ( 1 ) );                  // ui32, limited to 4.29e9 - JB

}

// Kernel that move particles to the voxelized volume boundary
__global__ void kernel_clear_deposition( DoseData *dose )
{
    const ui32 id = blockIdx.x * blockDim.x + threadIdx.x;
    if (id >= dose->tot_nb_dosels) return;

    dose->edep[ id ] = 0.0;
    dose->edep_squared[ id ] = 0.0;
    dose->number_of_hits[ id ] = 0;
}


/// Private /////////////////////////////////////////////////////////////////////

bool DoseCalculator::m_check_mandatory()
{
    if ( !m_flag_materials || !m_flag_phantom ) return false;
    else return true;
}

void DoseCalculator::m_uncertainty_calculation( ui32 dosel_id_x, ui32 dosel_id_y, ui32 dosel_id_z )
{

    // Relative statistical uncertainty (from Ma et al. PMB 47 2002 p1671) - JB
    //              /                                    \ ^1/2
    //              |    N*Sum(Edep^2) - Sum(Edep)^2     |
    //  relError =  | __________________________________ |
    //              |                                    |
    //              \         (N-1)*Sum(Edep)^2          /
    //
    //   where Edep represents the energy deposit in one hit and N the number of energy deposits (hits)

    // The same without developing - JB (from Walters, Kawrakow and Rogers Med. Phys. 29 2002)
    //                  /                                   \
    //             1    | Sum(Edep^2)      / Sum(Edep) \^2  |
    //  var(x) = _____  | ___________  --  |___________|    |
    //                  |                  |           |    |
    //            N-1   \     N            \    N      /    /
    //
    //  s(x) = ( var )^1/2
    //
    //  relError = s(x) / Sum(Edep)/N
    //

    ui32 index = dosel_id_z * h_dose->slice_nb_dosels + dosel_id_y * h_dose->nb_dosels.x + dosel_id_x;

    f64 N = h_dose->number_of_hits[index];
    f64 sum_E = h_dose->edep[index];

    if ( N > 1 && sum_E != 0.0 )
    {
        f64 sum_E2 = h_dose->edep_squared[index];
        f64 sum2_E = sum_E * sum_E;
        f64 s = ( (N*sum_E2) - sum2_E ) / ( (N-1) * sum2_E );

#ifdef DEBUG
        //assert(s >= 0.0);
        if ( s < 0.0 ) s = 1.0;
#endif
        m_uncertainty_values[ index ] = powf( s, 0.5 );
    }
    else
    {
        m_uncertainty_values[ index ] = 1.0;
    }

}

void DoseCalculator::m_dose_to_water_calculation( ui32 dosel_id_x, ui32 dosel_id_y, ui32 dosel_id_z )
{

    f64 vox_vol = h_dose->dosel_size.x * h_dose->dosel_size.y * h_dose->dosel_size.z;
    f64 density = 1.0 * gram/cm3;
    ui32 index = dosel_id_z * h_dose->slice_nb_dosels + dosel_id_y * h_dose->nb_dosels.x + dosel_id_x;

    m_dose_values[ index ] = h_dose->edep[ index ] / density / vox_vol / gray;

}

void DoseCalculator::m_dose_to_phantom_calculation( ui32 dosel_id_x, ui32 dosel_id_y, ui32 dosel_id_z )
{

    f64 vox_vol = h_dose->dosel_size.x * h_dose->dosel_size.y * h_dose->dosel_size.z;

    // Convert doxel_id into position
    f32 pos_x = ( dosel_id_x * h_dose->dosel_size.x ) - h_dose->offset.x;
    f32 pos_y = ( dosel_id_y * h_dose->dosel_size.y ) - h_dose->offset.y;
    f32 pos_z = ( dosel_id_z * h_dose->dosel_size.z ) - h_dose->offset.z;

    // Convert position into phantom voxel index
    f32xyz ivoxsize;
    ivoxsize.x = 1.0 / m_phantom.h_volume->spacing_x;
    ivoxsize.y = 1.0 / m_phantom.h_volume->spacing_y;
    ivoxsize.z = 1.0 / m_phantom.h_volume->spacing_z;
    ui32xyzw index_phantom;
    index_phantom.x = ui32 ( ( pos_x + m_phantom.h_volume->off_x ) * ivoxsize.x );
    index_phantom.y = ui32 ( ( pos_y + m_phantom.h_volume->off_y ) * ivoxsize.y );
    index_phantom.z = ui32 ( ( pos_z + m_phantom.h_volume->off_z ) * ivoxsize.z );
    index_phantom.w = index_phantom.z*m_phantom.h_volume->nb_vox_x*m_phantom.h_volume->nb_vox_y
                         + index_phantom.y*m_phantom.h_volume->nb_vox_x
                         + index_phantom.x; // linear index

#ifdef DEBUG
    assert( index_phantom.x < m_phantom.h_volume->nb_vox_x );
    assert( index_phantom.y < m_phantom.h_volume->nb_vox_y );
    assert( index_phantom.z < m_phantom.h_volume->nb_vox_z );
#endif

    // Get density for this voxel
    f64 density = m_materials.h_materials->density[ m_phantom.h_volume->values[ index_phantom.w ] ]; // density given by the material id

    // Compute the dose
    ui32 index = dosel_id_z * h_dose->slice_nb_dosels + dosel_id_y * h_dose->nb_dosels.x + dosel_id_x;

    if ( density > m_dose_min_density )
    {        
        m_dose_values[index] = h_dose->edep[ index ] / density / vox_vol / gray;
    }
    else
    {
        m_dose_values[index] = 0.0f;
    }
}

void DoseCalculator::m_copy_dosemap_to_gpu()
{
    ui32 n = h_dose->tot_nb_dosels;

    /// First, struct allocation
    HANDLE_ERROR( cudaMalloc( (void**) &d_dose, sizeof( DoseData ) ) );

    /// Device pointers allocation
    // Data
    f64 *edep;
    HANDLE_ERROR( cudaMalloc((void**) &edep, n*sizeof(f64)) );
    f64 *edep_squared;
    HANDLE_ERROR( cudaMalloc((void**) &edep_squared, n*sizeof(f64)) );
    ui32 *number_of_hits;
    HANDLE_ERROR( cudaMalloc((void**) &number_of_hits, n*sizeof(ui32)) );

    /// Copy host data to device
    HANDLE_ERROR( cudaMemcpy( edep, h_dose->edep,
                              n*sizeof(f64), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( edep_squared, h_dose->edep_squared,
                              n*sizeof(f64), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( number_of_hits, h_dose->number_of_hits,
                              n*sizeof(ui32), cudaMemcpyHostToDevice ) );

    /// Bind data to the struct
    HANDLE_ERROR( cudaMemcpy( &(d_dose->edep), &edep,
                              sizeof(d_dose->edep), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->edep_squared), &edep_squared,
                              sizeof(d_dose->edep_squared), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->number_of_hits), &number_of_hits,
                              sizeof(d_dose->number_of_hits), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->nb_dosels), &(h_dose->nb_dosels),
                              sizeof(d_dose->nb_dosels), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->dosel_size), &(h_dose->dosel_size),
                              sizeof(d_dose->dosel_size), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->inv_dosel_size), &(h_dose->inv_dosel_size),
                              sizeof(d_dose->inv_dosel_size), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->offset), &(h_dose->offset),
                              sizeof(d_dose->offset), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->xmin), &(h_dose->xmin),
                              sizeof(d_dose->xmin), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->xmax), &(h_dose->xmax),
                              sizeof(d_dose->xmax), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->ymin), &(h_dose->ymin),
                              sizeof(d_dose->ymin), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->ymax), &(h_dose->ymax),
                              sizeof(d_dose->ymax), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->zmin), &(h_dose->zmin),
                              sizeof(d_dose->zmin), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->zmax), &(h_dose->zmax),
                              sizeof(d_dose->zmax), cudaMemcpyHostToDevice ) );

    HANDLE_ERROR( cudaMemcpy( &(d_dose->tot_nb_dosels), &(h_dose->tot_nb_dosels),
                              sizeof(d_dose->tot_nb_dosels), cudaMemcpyHostToDevice ) );
    HANDLE_ERROR( cudaMemcpy( &(d_dose->slice_nb_dosels), &(h_dose->slice_nb_dosels),
                              sizeof(d_dose->slice_nb_dosels), cudaMemcpyHostToDevice ) );

}


void DoseCalculator::m_copy_dosemap_to_cpu()
{
    ui32 n = h_dose->tot_nb_dosels;

    /// Device pointers allocation
    f64 *edep;
    f64 *edep_squared;
    ui32 *number_of_hits;

    /// Bind data struct to new pointer
    HANDLE_ERROR( cudaMemcpy( &edep, &(d_dose->edep),
                              sizeof(d_dose->edep), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( &edep_squared, &(d_dose->edep_squared),
                              sizeof(d_dose->edep_squared), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( &number_of_hits, &(d_dose->number_of_hits),
                              sizeof(d_dose->number_of_hits), cudaMemcpyDeviceToHost ) );

    /// Copy device data to host
    HANDLE_ERROR( cudaMemcpy( h_dose->edep, edep,
                              n*sizeof(f64), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( h_dose->edep_squared, edep_squared,
                              n*sizeof(f64), cudaMemcpyDeviceToHost ) );
    HANDLE_ERROR( cudaMemcpy( h_dose->number_of_hits, number_of_hits,
                              n*sizeof(ui32), cudaMemcpyDeviceToHost ) );

}



/// Class
DoseCalculator::DoseCalculator()
{
    m_dosel_size.x = 0;
    m_dosel_size.y = 0;
    m_dosel_size.z = 0;

    m_offset.x = FLT_MAX;
    m_offset.y = FLT_MAX;
    m_offset.z = FLT_MAX;

    m_nb_of_dosels.x = 0;
    m_nb_of_dosels.y = 0;
    m_nb_of_dosels.z = 0;

    m_xmin = 0; m_xmax = 0;
    m_ymin = 0; m_ymax = 0;
    m_zmin = 0; m_zmax = 0;

    // Min density to compute the dose
    m_dose_min_density = 0.0;

    // Some flags
    m_flag_phantom = false;
    m_flag_materials = false;
    m_flag_dose_calculated = false;
    m_flag_uncertainty_calculated = false;

    // Init the struc
    h_dose = (DoseData*) malloc( sizeof(DoseData) );
    h_dose->edep = nullptr;
    h_dose->edep_squared = nullptr;
    h_dose->number_of_hits = nullptr;
    h_dose->nb_dosels.x = 0;
    h_dose->nb_dosels.y = 0;
    h_dose->nb_dosels.z = 0;
    h_dose->dosel_size.x = 0;
    h_dose->dosel_size.y = 0;
    h_dose->dosel_size.z = 0;
    h_dose->inv_dosel_size.x = 0;
    h_dose->inv_dosel_size.y = 0;
    h_dose->inv_dosel_size.z = 0;
    h_dose->offset.x = 0;
    h_dose->offset.y = 0;
    h_dose->offset.z = 0;
    h_dose->xmin = 0; h_dose->xmax = 0;
    h_dose->ymin = 0; h_dose->ymax = 0;
    h_dose->zmin = 0; h_dose->zmax = 0;
    h_dose->tot_nb_dosels = 0;
    h_dose->slice_nb_dosels = 0;

    // Dose and uncertainty values
    m_dose_values = NULL;
    m_uncertainty_values = NULL;

    // Init other struct
    mh_params = nullptr;
    d_dose = nullptr;

}

DoseCalculator::~DoseCalculator()
{

}

/// Setting

void DoseCalculator::set_dosel_size ( f32 sx, f32 sy, f32 sz )
{
    m_dosel_size = make_f32xyz( sx, sy, sz );
}

void DoseCalculator::set_voi( f32 xmin, f32 xmax, f32 ymin, f32 ymax, f32 zmin, f32 zmax )
{
    m_xmin = xmin; m_xmax = xmax;
    m_ymin = ymin; m_ymax = ymax;
    m_zmin = zmin; m_zmax = zmax;
}

/*
void DoseCalculator::set_offset ( f32 ox, f32 oy, f32 oz )
{
    dose.data_h.ox = ox;
    dose.data_h.oy = oy;
    dose.data_h.oz = oz;
}
*/

void DoseCalculator::set_voxelized_phantom ( VoxelizedPhantom aphantom )
{
    m_phantom = aphantom;
    m_flag_phantom = true;
}

void DoseCalculator::set_materials ( Materials materials )
{
    m_materials = materials;
    m_flag_materials = true;
}

// In g/cm3 ? TODO - JB
void DoseCalculator::set_min_density ( f32 min )
{
    m_dose_min_density = min;
}

VoxVolumeData<f32> * DoseCalculator::get_dose_map()
{
    if ( !m_flag_dose_calculated )
    {
        GGwarn << "DoseCalculator, dose map was not calculated! Compute dose to water." << GGendl;
        calculate_dose_to_water();
    }

    VoxVolumeData<f32> *dosemap = new VoxVolumeData<f32>;
    dosemap->nb_vox_x = h_dose->nb_dosels.x;
    dosemap->nb_vox_y = h_dose->nb_dosels.y;
    dosemap->nb_vox_z = h_dose->nb_dosels.z;

    dosemap->off_x = h_dose->offset.x;
    dosemap->off_y = h_dose->offset.y;
    dosemap->off_z = h_dose->offset.z;

    dosemap->spacing_x = h_dose->dosel_size.x;
    dosemap->spacing_y = h_dose->dosel_size.y;
    dosemap->spacing_z = h_dose->dosel_size.z;

    dosemap->number_of_voxels = h_dose->tot_nb_dosels;

    dosemap->xmin = h_dose->xmin;
    dosemap->xmax = h_dose->xmax;
    dosemap->ymin = h_dose->ymin;
    dosemap->ymax = h_dose->ymax;
    dosemap->zmin = h_dose->zmin;
    dosemap->zmax = h_dose->zmax;

    dosemap->values = m_dose_values;

    return dosemap;
}

VoxVolumeData<f32> * DoseCalculator::get_uncertainty_map()
{
    if ( !m_flag_dose_calculated )
    {
        GGwarn << "DoseCalculator, dose map was not calculated! Compute dose to water." << GGendl;
        calculate_dose_to_water();
    }

    VoxVolumeData<f32> *uncert = new VoxVolumeData<f32>;
    uncert->nb_vox_x = h_dose->nb_dosels.x;
    uncert->nb_vox_y = h_dose->nb_dosels.y;
    uncert->nb_vox_z = h_dose->nb_dosels.z;

    uncert->off_x = h_dose->offset.x;
    uncert->off_y = h_dose->offset.y;
    uncert->off_z = h_dose->offset.z;

    uncert->spacing_x = h_dose->dosel_size.x;
    uncert->spacing_y = h_dose->dosel_size.y;
    uncert->spacing_z = h_dose->dosel_size.z;

    uncert->number_of_voxels = h_dose->tot_nb_dosels;

    uncert->xmin = h_dose->xmin;
    uncert->xmax = h_dose->xmax;
    uncert->ymin = h_dose->ymin;
    uncert->ymax = h_dose->ymax;
    uncert->zmin = h_dose->zmin;
    uncert->zmax = h_dose->zmax;

    uncert->values = m_uncertainty_values;

    return uncert;

}

/// Updating/clearing

void DoseCalculator::clear_deposition()
{
    // Clear all maps
    ui32 i=0; while (i < h_dose->tot_nb_dosels)
    {
        h_dose->edep[i] = 0.0;
        h_dose->edep_squared[i] = 0.0;
        h_dose->number_of_hits[i] = 0;
        ++i;
    }

    dim3 threads, grid;
    threads.x = mh_params->gpu_block_size;
    grid.x = ( h_dose->tot_nb_dosels + mh_params->gpu_block_size - 1 ) / mh_params->gpu_block_size;

    kernel_clear_deposition<<<grid, threads>>>( d_dose );
    cudaDeviceSynchronize();
    cuda_error_check("Error ", " Kernel_clear_deposition (DoseCalculator)");

}


/// Init
void DoseCalculator::initialize ( GlobalSimulationParametersData *h_params )
{
//     GGcout << " DoseCalculator initialize " << GGendl;
    
    // Check if everything was set properly
    if ( !m_check_mandatory() )
    {
        print_error ( "Dose calculator, phantom and materials are not set?!" );
        exit_simulation();
    }

    // Copy params
    mh_params = h_params;

    /// Compute dosemap parameters /////////////////////////////

    // Select a doxel size
    if ( m_dosel_size.x > 0.0 && m_dosel_size.y > 0.0 && m_dosel_size.z > 0.0 )
    {
        h_dose->dosel_size = m_dosel_size;
        h_dose->inv_dosel_size = fxyz_inv( m_dosel_size );
    }
    else
    {
        h_dose->dosel_size = make_f32xyz( m_phantom.h_volume->spacing_x,
                                       m_phantom.h_volume->spacing_y,
                                       m_phantom.h_volume->spacing_z );
        h_dose->inv_dosel_size = fxyz_inv( h_dose->dosel_size );
    }

/*
    // Compute min-max volume of interest
    f32xyz phan_size = make_f32xyz( m_phantom.h_volume->nb_vox_x * m_phantom.h_volume->spacing_x,
                                    m_phantom.h_volume->nb_vox_y * m_phantom.h_volume->spacing_y,
                                    m_phantom.h_volume->nb_vox_z * m_phantom.h_volume->spacing_z );
    f32xyz half_phan_size = fxyz_scale( phan_size, 0.5f );
    f32 phan_xmin = -half_phan_size.x; f32 phan_xmax = half_phan_size.x;
    f32 phan_ymin = -half_phan_size.y; f32 phan_ymax = half_phan_size.y;
    f32 phan_zmin = -half_phan_size.z; f32 phan_zmax = half_phan_size.z;
    */

    // Select a min-max VOI
    if ( !m_xmin && !m_xmax && !m_ymin && !m_ymax && !m_zmin && !m_zmax )
    {
        h_dose->xmin = m_phantom.h_volume->xmin;
        h_dose->xmax = m_phantom.h_volume->xmax;
        h_dose->ymin = m_phantom.h_volume->ymin;
        h_dose->ymax = m_phantom.h_volume->ymax;
        h_dose->zmin = m_phantom.h_volume->zmin;
        h_dose->zmax = m_phantom.h_volume->zmax;
    }
    else
    {
        h_dose->xmin = m_xmin;
        h_dose->xmax = m_xmax;
        h_dose->ymin = m_ymin;
        h_dose->ymax = m_ymax;
        h_dose->zmin = m_zmin;
        h_dose->zmax = m_zmax;
    }

    // Get the current dimension of the dose map
    f32xyz cur_dose_size = make_f32xyz( h_dose->xmax - h_dose->xmin,
                                        h_dose->ymax - h_dose->ymin,
                                        h_dose->zmax - h_dose->zmin );

    // New nb of voxels
    h_dose->nb_dosels.x = floor( cur_dose_size.x / h_dose->dosel_size.x );
    h_dose->nb_dosels.y = floor( cur_dose_size.y / h_dose->dosel_size.y );
    h_dose->nb_dosels.z = floor( cur_dose_size.z / h_dose->dosel_size.z );
    h_dose->slice_nb_dosels = h_dose->nb_dosels.x * h_dose->nb_dosels.y;
    h_dose->tot_nb_dosels = h_dose->slice_nb_dosels * h_dose->nb_dosels.z;

    // Compute the new size (due to integer nb of doxels)
    f32xyz new_dose_size = fxyz_mul( h_dose->dosel_size, cast_ui32xyz_to_f32xyz( h_dose->nb_dosels ) );

    if ( new_dose_size.x <= 0.0 || new_dose_size.y <= 0.0 || new_dose_size.z <= 0.0 )
    {
        GGcerr << "Dosemap dimension: "
               << new_dose_size.x << " "
               << new_dose_size.y << " "
               << new_dose_size.z << GGendl;
        exit_simulation();
    }

    // Compute new min and max after voxel alignment // TODO: Check here, offset is not considered? - JB
    f32xyz half_delta_size = fxyz_scale( fxyz_sub( cur_dose_size, new_dose_size ), 0.5f );

    h_dose->xmin += half_delta_size.x;
    h_dose->xmax -= half_delta_size.x;

    h_dose->ymin += half_delta_size.y;
    h_dose->ymax -= half_delta_size.y;

    h_dose->zmin += half_delta_size.z;
    h_dose->zmax -= half_delta_size.z;

    // Get the new offset
    h_dose->offset.x = m_phantom.h_volume->off_x - ( h_dose->xmin - m_phantom.h_volume->xmin );
    h_dose->offset.y = m_phantom.h_volume->off_y - ( h_dose->ymin - m_phantom.h_volume->ymin );
    h_dose->offset.z = m_phantom.h_volume->off_z - ( h_dose->zmin - m_phantom.h_volume->zmin );

    // Init dose map
    h_dose->edep = (f64*)malloc( h_dose->tot_nb_dosels*sizeof(f64) );
    h_dose->edep_squared = (f64*)malloc( h_dose->tot_nb_dosels*sizeof(f64) );
    h_dose->number_of_hits = (ui32*)malloc( h_dose->tot_nb_dosels*sizeof(ui32) );
    ui32 i=0; while (i < h_dose->tot_nb_dosels)
    {
        h_dose->edep[i] = 0.0;
        h_dose->edep_squared[i] = 0.0;
        h_dose->number_of_hits[i] = 0;
        ++i;
    }

    //////////////////////////////////////////////////////////

    // Host allocation
    m_dose_values = (f32*)malloc( h_dose->tot_nb_dosels * sizeof(f32) );
    m_uncertainty_values = (f32*)malloc( h_dose->tot_nb_dosels * sizeof(f32) );

    // Device allocation and copy
    m_copy_dosemap_to_gpu();

}

void DoseCalculator::calculate_dose_to_water()
{
    if (mh_params->verbose) GGcout << "Compute dose to water" << GGendl;

    m_copy_dosemap_to_cpu();

    // Calculate the dose to water and the uncertainty
    for ( ui32 iz=0; iz < h_dose->nb_dosels.z; iz++ )
    {
        for ( ui32 iy=0; iy < h_dose->nb_dosels.y; iy++ )
        {
            for ( ui32 ix=0; ix < h_dose->nb_dosels.x; ix++ )
            {
                m_dose_to_water_calculation( ix, iy, iz );
                m_uncertainty_calculation( ix, iy, iz );
            }
        }
    }

    m_flag_dose_calculated = true;
    m_flag_uncertainty_calculated = true;
}

void DoseCalculator::calculate_dose_to_medium()
{
    // Check if everything was set properly
    if ( !m_flag_materials || !m_flag_phantom )
    {
        GGcerr << "Dose calculator, phantom and materials data are required!" << GGendl;
        exit_simulation();
    }

    if (mh_params->verbose) GGcout << "Compute dose to medium" << GGendl;

    m_copy_dosemap_to_cpu();

    // Calculate the dose to phantom and the uncertainty
    for ( ui32 iz=0; iz < h_dose->nb_dosels.z; iz++ )
    {
        for ( ui32 iy=0; iy < h_dose->nb_dosels.y; iy++ )
        {
            for ( ui32 ix=0; ix < h_dose->nb_dosels.x; ix++ )
            {
                m_dose_to_phantom_calculation( ix, iy, iz );
                m_uncertainty_calculation( ix, iy, iz );
            }
        }
    }
    
    m_flag_dose_calculated = true;
    m_flag_uncertainty_calculated = true;

}

void DoseCalculator::dose_scaling( f32 factor )
{
    if ( !m_flag_dose_calculated )
    {
        GGcerr << "Dose calculator, the dose map was not calculated, not possible to scale it!" << GGendl;
    }
    else
    {
        ui32 n = h_dose->tot_nb_dosels;
        ui32 i = 0; while( i < n)
        {
            m_dose_values[i++] *= factor;
        }
    }
}

void DoseCalculator::write(std::string filename , std::string option )
{
    // Transform the name of option in small letter
    std::transform( option.begin(), option.end(), option.begin(), ::tolower );
    std::string edep( "energy" );
    std::string dose( "dose" );
    std::string unc( "uncertainty" );
    std::string edepSq( "energysquared" );
    std::string hit( "hit" );

    ui8 flag_edep = false;
    ui8 flag_edepSq = false;
    ui8 flag_dose = false;
    ui8 flag_unc = false;
    ui8 flag_hit = false;

    if ( option == "all" )
    {
        flag_edep = true;
        flag_edepSq = true;
        flag_dose = true;
        flag_unc = true;
        flag_hit = true;
    }
    else
    {
        if ( option.find(edep) != std::string::npos )
        {
            flag_edep = true;
        }

        if ( option.find(edepSq) != std::string::npos )
        {
            flag_edepSq = true;
        }

        if ( option.find(dose) != std::string::npos )
        {
            flag_dose = true;
        }

        if ( option.find(unc) != std::string::npos )
        {
            flag_unc = true;
        }

        if ( option.find(hit) != std::string::npos )
        {
            flag_hit = true;
        }

        if ( !flag_edep && !flag_edepSq && !flag_dose && !flag_unc && !flag_hit )
        {
            GGwarn << "No options to export the results from the DoseCalculator were recognized!" << GGendl;
            return;
        }
    }

    // Update host dose data
    m_copy_dosemap_to_cpu();

    // Create an IO object
    ImageIO *im_io = new ImageIO;

    std::string format = im_io->get_extension( filename );
    filename = im_io->get_filename_without_extension( filename );

    // Convert Edep and EdepSquared from f64 to f32
    ui32 tot = h_dose->nb_dosels.x*h_dose->nb_dosels.y*h_dose->nb_dosels.z;
    f32 *f32edep = new f32[ tot ];
    f32 *f32edepSq = new f32[ tot ];
    ui32 i=0; while ( i < tot )
    {
        f32edep[ i ] = (f32)h_dose->edep[ i ];
        f32edepSq[ i ] = (f32)h_dose->edep_squared[ i ];
        ++i;
    }

    // Get output name
    std::string edep_out( filename + "-Edep." + format );
    std::string edep_squared_out( filename + "-EdepSquared." + format );
    std::string uncer_out( filename + "-Uncertainty." + format );
    std::string hit_out( filename + "-Hit." + format );
    std::string dose_out( filename + "-Dose." + format );

    // Export Edep and EdepSquared
    if ( flag_edep )
    {
        im_io->write_3D( edep_out, f32edep, h_dose->nb_dosels, h_dose->offset, h_dose->dosel_size );
        if (mh_params->verbose) GGcout << "Write image " << edep_out << " ... " << GGendl;
    }
    if ( flag_edepSq )
    {
        im_io->write_3D( edep_squared_out, f32edepSq, h_dose->nb_dosels, h_dose->offset, h_dose->dosel_size );
        if (mh_params->verbose) GGcout << "Write image " << edep_squared_out << " ... " << GGendl;
    }

    // Export uncertainty
    if ( !m_flag_uncertainty_calculated && flag_unc )
    {
        // Calculate the dose to phantom and the uncertainty
        for ( ui32 iz=0; iz < h_dose->nb_dosels.z; iz++ )
        {
            for ( ui32 iy=0; iy < h_dose->nb_dosels.y; iy++ )
            {
                for ( ui32 ix=0; ix < h_dose->nb_dosels.x; ix++ )
                {
                    m_uncertainty_calculation( ix, iy, iz );
                }
            }
        }
    }

    // Export uncertainty and hits
    if ( flag_unc )
    {
        im_io->write_3D( uncer_out, m_uncertainty_values, h_dose->nb_dosels, h_dose->offset, h_dose->dosel_size );
        if (mh_params->verbose) GGcout << "Write image " << uncer_out << " ... " << GGendl;
    }
    if ( flag_hit )
    {
        im_io->write_3D( hit_out, h_dose->number_of_hits, h_dose->nb_dosels, h_dose->offset, h_dose->dosel_size );
        if (mh_params->verbose) GGcout << "Write image " << hit_out << " ... " << GGendl;
    }

    // Export dose
    if ( m_flag_dose_calculated && flag_dose )
    {
        im_io->write_3D( dose_out, m_dose_values, h_dose->nb_dosels, h_dose->offset, h_dose->dosel_size );
        if (mh_params->verbose) GGcout << "Write image " << dose_out << " ... " << GGendl;
    }

    delete im_io;
    delete f32edep, f32edepSq;

}



#endif
