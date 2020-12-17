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
  \file generate_volume.cc

  \brief Example of volume creation

  \author Julien BERT <julien.bert@univ-brest.fr>
  \author Didier BENOIT <didier.benoit@inserm.fr>
  \author LaTIM, INSERM - U1101, Brest, FRANCE
  \version 1.0
  \date Monday November 2, 2020
*/

#include <cstdlib>

#include "GGEMS/global/GGEMSOpenCLManager.hh"

#include "GGEMS/geometries/GGEMSVolumeCreatorManager.hh"
#include "GGEMS/geometries/GGEMSBox.hh"
#include "GGEMS/geometries/GGEMSTube.hh"
#include "GGEMS/geometries/GGEMSSphere.hh"

#include "GGEMS/tools/GGEMSPrint.hh"

/*!
  \fn int main(void)
  \return status of program
  \brief main function of program
*/
int main(void)
{
  // Initialization of singletons
  GGEMSOpenCLManager& opencl_manager = GGEMSOpenCLManager::GetInstance();
  GGEMSVolumeCreatorManager& volume_creator_manager = GGEMSVolumeCreatorManager::GetInstance();

  // Set the context id
  opencl_manager.ContextToActivate(0);

  // Initializing a global voxelized volume
  volume_creator_manager.SetVolumeDimensions(450, 450, 450);
  volume_creator_manager.SetElementSizes(0.5f, 0.5f, 0.5f, "mm");
  volume_creator_manager.SetOutputImageFilename("data/volume");
  volume_creator_manager.SetRangeToMaterialDataFilename("data/range_volume");
  volume_creator_manager.SetMaterial("Air");
  volume_creator_manager.SetDataType("MET_INT");
  volume_creator_manager.Initialize();

  // Creating a box
  GGEMSBox* box = new GGEMSBox(24.0f, 36.0f, 56.0f, "mm");
  box->SetPosition(-70.0f, -30.0f, 10.0f, "mm");
  box->SetLabelValue(1);
  box->SetMaterial("Water");
  box->Initialize();
  box->Draw();
  delete box;

  // Creating a tube
  GGEMSTube* tube = new GGEMSTube(13.0f, 8.0f, 50.0f, "mm");
  tube->SetPosition(20.0f, 10.0f, -2.0f, "mm");
  tube->SetLabelValue(2);
  tube->SetMaterial("Calcium");
  tube->Initialize();
  tube->Draw();
  delete tube;

  // Creating a sphere
  GGEMSSphere* sphere = new GGEMSSphere(14.0f, "mm");
  sphere->SetPosition(30.0f, -30.0f, 8.0f, "mm");
  sphere->SetLabelValue(3);
  sphere->SetMaterial("Lung");
  sphere->Initialize();
  sphere->Draw();
  delete sphere;

  // Writing volume
  volume_creator_manager.Write();

  exit(EXIT_SUCCESS);
}
