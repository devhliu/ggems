/*!
  \file GGEMSVoxelizedPhantomNavigatorImagery.hh

  \brief GGEMS class managing voxelized phantom navigator for imagery application

  \author Julien BERT <julien.bert@univ-brest.fr>
  \author Didier BENOIT <didier.benoit@inserm.fr>
  \author LaTIM, INSERM - U1101, Brest, FRANCE
  \version 1.0
  \date Tuesday February 11, 2020
*/

#include "GGEMS/geometries/GGEMSVoxelizedPhantomNavigatorImagery.hh"
#include "GGEMS/geometries/GGEMSPhantomNavigatorManager.hh"
#include "GGEMS/tools/GGEMSSystemOfUnits.hh"
#include "GGEMS/tools/GGEMSPrint.hh"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSVoxelizedPhantomNavigatorImagery::GGEMSVoxelizedPhantomNavigatorImagery(
  void)
: GGEMSPhantomNavigator(this)
{
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery",
    "GGEMSVoxelizedPhantomNavigatorImagery", 3)
    << "Allocation of GGEMSVoxelizedPhantomNavigatorImagery..." << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSVoxelizedPhantomNavigatorImagery::~GGEMSVoxelizedPhantomNavigatorImagery(
  void)
{
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery",
    "~GGEMSVoxelizedPhantomNavigatorImagery", 3)
    << "Deallocation of GGEMSVoxelizedPhantomNavigatorImagery..." << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void GGEMSVoxelizedPhantomNavigatorImagery::PrintInfos(void) const
{
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0) << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "GGEMSVoxelizedPhantomNavigatorImagery Infos: " << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "--------------------------------------------" << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "*Phantom navigator name: " << phantom_navigator_name_ << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "*Phantom header filename: " << phantom_mhd_header_filename_ << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "*Range label to material filename: " << range_data_filename_ << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0)
    << "*Geometry tolerance: " << geometry_tolerance_/GGEMSUnits::mm
    << " mm" << GGendl;
  GGcout("GGEMSVoxelizedPhantomNavigatorImagery", "PrintInfos", 0) << GGendl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

GGEMSVoxelizedPhantomNavigatorImagery*
  create_ggems_voxelized_phantom_navigator_imagery(void)
{
  return new(std::nothrow) GGEMSVoxelizedPhantomNavigatorImagery;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_phantom_name_ggems_voxelized_phantom_navigator_imagery(
  GGEMSVoxelizedPhantomNavigatorImagery* p_voxelized_phantom_navigator_imagery,
  char const* phantom_navigator_name)
{
  p_voxelized_phantom_navigator_imagery->SetPhantomName(phantom_navigator_name);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_phantom_file_ggems_voxelized_phantom_navigator_imagery(
  GGEMSVoxelizedPhantomNavigatorImagery* p_voxelized_phantom_navigator_imagery,
  char const* phantom_filename)
{
  p_voxelized_phantom_navigator_imagery->SetPhantomFile(phantom_filename);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_range_to_material_filename_ggems_voxelized_phantom_navigator_imagery(
  GGEMSVoxelizedPhantomNavigatorImagery* p_voxelized_phantom_navigator_imagery,
  char const* range_data_filename)
{
  p_voxelized_phantom_navigator_imagery->SetRangeToMaterialFile(
    range_data_filename);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

void set_geometry_tolerance_ggems_voxelized_phantom_navigator_imagery(
  GGEMSVoxelizedPhantomNavigatorImagery* p_voxelized_phantom_navigator_imagery,
  GGdouble const distance, char const* unit)
{
  p_voxelized_phantom_navigator_imagery->SetGeometryTolerance(distance, unit);
}
