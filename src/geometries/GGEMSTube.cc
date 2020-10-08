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
  \file GGEMSTube.cc

  \brief Class GGEMSTube inheriting from GGEMSVolumeSolid handling Tube solid

  \author Julien BERT <julien.bert@univ-brest.fr>
  \author Didier BENOIT <didier.benoit@inserm.fr>
  \author LaTIM, INSERM - U1101, Brest, FRANCE
  \version 1.0
  \date Monday January 13, 2020
*/

#include "GGEMS/geometries/GGEMSTube.hh"
#include "GGEMS/tools/GGEMSTools.hh"
#include "GGEMS/tools/GGEMSSystemOfUnits.hh"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSTube::GGEMSTube(void)
: GGEMSVolume(),
  height_(0.0),
  radius_(0.0)
{
  GGcout("GGEMSTube", "GGEMSTube", 3) << "Allocation of GGEMSTube..." << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSTube::~GGEMSTube(void)
{
  GGcout("GGEMSTube", "~GGEMSTube", 3) << "Deallocation of GGEMSTube..." << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSTube::SetHeight(GGfloat const& height, char const* unit)
{
  height_ = DistanceUnit(height, unit);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSTube::SetRadius(GGfloat const& radius, char const* unit)
{
  radius_ = DistanceUnit(radius, unit);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSTube::CheckParameters(void) const
{
  GGcout("GGEMSTube", "CheckParameters", 3) << "Checking mandatory parameters..." << GGendl;

  // Checking radius
  if (radius_ == 0.0f) {
    GGEMSMisc::ThrowException("GGEMSTube", "CheckParameters", "The tube radius has to be > 0!!!");
  }

  // Checking height
  if (height_ == 0.0f) {
    GGEMSMisc::ThrowException("GGEMSTube", "CheckParameters", "The tube height has to be > 0!!!");
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSTube::Initialize(void)
{
  GGcout("GGEMSTube", "Initialize", 3) << "Initializing GGEMSTube solid volume..." << GGendl;

  // Check mandatory parameters
  CheckParameters();

  // Getting the path to kernel
  std::string const kOpenCLKernelPath = OPENCL_KERNEL_PATH;
  std::string const kFilename = kOpenCLKernelPath + "/DrawGGEMSTube.cl";

  // Get the volume creator manager
  GGEMSVolumeCreatorManager& volume_creator_manager = GGEMSVolumeCreatorManager::GetInstance();

  // Get the OpenCL manager
  GGEMSOpenCLManager& opencl_manager = GGEMSOpenCLManager::GetInstance();

  // Get the data type and compiling kernel
  std::string const kDataType = "-D" + volume_creator_manager.GetDataType();
  kernel_draw_volume_cl_ = opencl_manager.CompileKernel(kFilename, "draw_ggems_tube", nullptr, const_cast<char*>(kDataType.c_str()));
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSTube::Draw(void)
{
  GGcout("GGEMSTube", "Draw", 3) << "Drawing Tube..." << GGendl;

  // Get the OpenCL manager
  GGEMSOpenCLManager& opencl_manager = GGEMSOpenCLManager::GetInstance();

  // Get the volume creator manager
  GGEMSVolumeCreatorManager& volume_creator_manager = GGEMSVolumeCreatorManager::GetInstance();

  // Get command queue and event
  cl::CommandQueue* p_queue_cl = opencl_manager.GetCommandQueue();
  cl::Event* p_event_cl = opencl_manager.GetEvent();

  // Get parameters from phantom creator
  GGfloat3 const kVoxelSizes = volume_creator_manager.GetElementsSizes();
  GGuint3 const kPhantomDimensions = volume_creator_manager.GetVolumeDimensions();
  GGulong const kNumberThreads = volume_creator_manager.GetNumberElements();
  cl::Buffer* voxelized_phantom = volume_creator_manager.GetVoxelizedVolume();

  // Set parameters for kernel
  std::shared_ptr<cl::Kernel> kernel_cl = kernel_draw_volume_cl_.lock();
  kernel_cl->setArg(0, kVoxelSizes);
  kernel_cl->setArg(1, kPhantomDimensions);
  kernel_cl->setArg(2, positions_);
  kernel_cl->setArg(3, label_value_);
  kernel_cl->setArg(4, height_);
  kernel_cl->setArg(5, radius_);
  kernel_cl->setArg(6, *voxelized_phantom);

  // Define the number of work-item to launch
  cl::NDRange global(kNumberThreads);
  cl::NDRange offset(0);

  // Launching kernel
  cl_int kernel_status = p_queue_cl->enqueueNDRangeKernel(*kernel_cl, offset, global, cl::NullRange, nullptr, p_event_cl);
  opencl_manager.CheckOpenCLError(kernel_status, "GGEMSTube", "Draw Tube");
  p_queue_cl->finish(); // Wait until the kernel status is finish

  // Displaying time in kernel
  opencl_manager.DisplayElapsedTimeInKernel("Draw Tube");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSTube* create_tube(void)
{
  return new(std::nothrow) GGEMSTube;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void delete_tube(GGEMSTube* tube)
{
  if (tube) {
    delete tube;
    tube = nullptr;
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_height_tube(GGEMSTube* tube, GGfloat const height, char const* unit)
{
  tube->SetHeight(height, unit);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_radius_tube(GGEMSTube* tube, GGfloat const radius, char const* unit)
{
  tube->SetRadius(radius, unit);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_position_tube(GGEMSTube* tube, GGfloat const pos_x, GGfloat const pos_y, GGfloat const pos_z, char const* unit)
{
  tube->SetPosition(pos_x, pos_y, pos_z, unit);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_material_tube(GGEMSTube* tube, char const* material)
{
  tube->SetMaterial(material);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_label_value_tube(GGEMSTube* tube, GGfloat const label_value)
{
  tube->SetLabelValue(label_value);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void initialize_tube(GGEMSTube* tube)
{
  tube->Initialize();
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void draw_tube(GGEMSTube* tube)
{
  tube->Draw();
}
