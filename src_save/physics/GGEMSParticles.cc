// ************************************************************************
// * This file is part of GGEMS.                                          *
// *                                                                      *
// * GGEMS is free software: you can redistribute it and/or modify        *
// * it under the terms of the GNU General Public License as published by *
// * the Free Software Foundation, either version 3 of the License, or    *
// * (at your option) any later version.                                  *
// *                                                                      *
// * GGEMS is distributed in the hope that it will be useful,             *
// * but WITHOUT ANY WARRANTY; without even the implied warranty of       *
// * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *
// * GNU General Public License for more details.                         *
// *                                                                      *
// * You should have received a copy of the GNU General Public License    *
// * along with GGEMS.  If not, see <https://www.gnu.org/licenses/>.      *
// *                                                                      *
// ************************************************************************

/*!
  \file GGEMSParticles.cc

  \brief Class managing the particles in GGEMS

  \author Julien BERT <julien.bert@univ-brest.fr>
  \author Didier BENOIT <didier.benoit@inserm.fr>
  \author LaTIM, INSERM - U1101, Brest, FRANCE
  \version 1.0
  \date Thrusday October 3, 2019
*/

#include "GGEMS/physics/GGEMSPrimaryParticles.hh"
#include "GGEMS/sources/GGEMSSourceManager.hh"
#include "GGEMS/tools/GGEMSRAMManager.hh"
#include "GGEMS/navigators/GGEMSNavigatorManager.hh"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSParticles::GGEMSParticles(void)
: number_of_particles_(0),
  primary_particles_(nullptr)
{
  GGcout("GGEMSParticles", "GGEMSParticles", 3) << "Allocation of GGEMSParticles..." << GGendl;

  particle_type_.insert(std::make_pair(0, "PHOTON"));
  particle_type_.insert(std::make_pair(1, "ELECTRON"));
  particle_type_.insert(std::make_pair(2, "POSITRON"));

  particle_status_.insert(std::make_pair(0, "ALIVE"));
  particle_status_.insert(std::make_pair(1, "DEAD"));
  particle_status_.insert(std::make_pair(2, "FREEZE"));

  particle_level_.insert(std::make_pair(0, "PRIMARY"));
  particle_level_.insert(std::make_pair(1, "SECONDARY"));
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSParticles::~GGEMSParticles(void)
{
  GGcout("GGEMSParticles", "~GGEMSParticles", 3) << "Deallocation of GGEMSParticles..." << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSParticles::SetNumberOfParticles(GGsize const& number_of_particles)
{
  number_of_particles_ = number_of_particles;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSParticles::Initialize(void)
{
  GGcout("GGEMSParticles", "Initialize", 1) << "Initialization of GGEMSParticles..." << GGendl;

  // Allocation of the PrimaryParticle structure
  AllocatePrimaryParticles();
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

bool GGEMSParticles::IsAlive(void) const
{
  GGcout("GGEMSParticles", "AllocatePrimaryParticles", 3) << "Checking if some particles are still alive..." << GGendl;

  // Get the OpenCL manager
  GGEMSOpenCLManager& opencl_manager = GGEMSOpenCLManager::GetInstance();

  // Get pointer on OpenCL device for particles
  GGEMSPrimaryParticles* primary_particles_device = opencl_manager.GetDeviceBuffer<GGEMSPrimaryParticles>(primary_particles_.get(), sizeof(GGEMSPrimaryParticles));

  // Loop over the number of particles
  bool status = false;
  for (GGsize i = 0; i < number_of_particles_; ++i) {
    if (primary_particles_device->status_[i] == ALIVE) {
      status = true;
      break;
    }
  }

  // Release the pointer
  opencl_manager.ReleaseDeviceBuffer(primary_particles_.get(), primary_particles_device);
  return status;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSParticles::AllocatePrimaryParticles(void)
{
  GGcout("GGEMSParticles", "AllocatePrimaryParticles", 1) << "Allocation of primary particles..." << GGendl;

  // Get the OpenCL manager
  GGEMSOpenCLManager& opencl_manager = GGEMSOpenCLManager::GetInstance();

  // Allocation of memory on OpenCL device
  primary_particles_ = opencl_manager.Allocate(nullptr, sizeof(GGEMSPrimaryParticles), CL_MEM_READ_WRITE, "GGEMSParticles");
}