#ifndef GUARD_GGEMS_PHYSICS_GGEMSCOMPTONSCATTERINGMODELS_HH
#define GUARD_GGEMS_PHYSICS_GGEMSCOMPTONSCATTERINGMODELS_HH

/*!
  \file GGEMSComptonScatteringModels.hh

  \brief Models for Compton scattering, only for OpenCL kernel usage

  \author Julien BERT <julien.bert@univ-brest.fr>
  \author Didier BENOIT <didier.benoit@inserm.fr>
  \author LaTIM, INSERM - U1101, Brest, FRANCE
  \version 1.0
  \date Friday September 11, 2020
*/

#ifdef OPENCL_COMPILER

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/*!
  \fn inline void KleinNishinaComptonSampleSecondaries(__global GGEMSPrimaryParticles* primary_particle, __global GGEMSRandom* random, GGint const index_particle)
  \param primary_particle - buffer of particles
  \param random - pointer on random numbers
  \param index_particle - index of the particle
  \brief Klein Nishina Compton model, Effects due to binding of atomic electrons are negliged.
*/
inline void KleinNishinaComptonSampleSecondaries(
  __global GGEMSPrimaryParticles* primary_particle,
  __global GGEMSRandom* random,
  GGint const index_particle
)
{
  // Energy
  GGfloat const kE0 = primary_particle->E_[index_particle];
  GGfloat const kE0_MeC2 = kE0 / ELECTRON_MASS_C2;

  // Direction
  GGfloat3 const kGammaDirection = {
    primary_particle->dx_[index_particle],
    primary_particle->dy_[index_particle],
    primary_particle->dz_[index_particle]
  };

  // sample the energy rate the scattered gamma
  GGfloat const kEps0 = 1.0f / (1.0f + 2.0f*kE0_MeC2);
  GGfloat const kEps0Eps0 = kEps0*kEps0;
  GGfloat const kAlpha1 = -log(kEps0);
  GGfloat const kAlpha2 = kAlpha1 + 0.5f*(1.0f-kEps0Eps0);

  #ifdef GGEMS_TRACKING
  if (index_particle == primary_particle->particle_tracking_id) {
    printf("\n");
    printf("[GGEMS OpenCL function KleinNishinaComptonSampleSecondaries]     Photon energy: %e keV\n", kE0/keV);
    printf("[GGEMS OpenCL function KleinNishinaComptonSampleSecondaries]     Photon direction: %e %e %e\n", kGammaDirection.x, kGammaDirection.y, kGammaDirection.z);
    printf("[GGEMS OpenCL function KleinNishinaComptonSampleSecondaries]     Min. photon energy (back scattering): %e keV\n", kE0*kEps0/keV);
  }
  #endif

  // sample the energy rate of the scattered gamma

  GGfloat3 rndm;
  GGfloat epsilon, epsilonsq, onecost, sint2, greject, costheta, sintheta, phi;
  GGint nloop = 0;
  do {
    ++nloop;
    // false interaction if too many iterations
    if (nloop > 1000) return;

    // Get 3 random numbers
    rndm.x = KissUniform(random, index_particle);
    rndm.y = KissUniform(random, index_particle);
    rndm.z = KissUniform(random, index_particle);

    if (kAlpha1 > kAlpha2*rndm.x) {
      epsilon = exp(-kAlpha1*rndm.y);
      epsilonsq = epsilon*epsilon; 
    }
    else {
      epsilonsq = kEps0Eps0 + (1.0f - kEps0Eps0)*rndm.y;
      epsilon = sqrt(epsilonsq);
    }

    onecost = (1.0f - epsilon)/(epsilon*kE0_MeC2);
    sint2 = onecost*(2.0f-onecost);
    greject = 1.0f - epsilon*sint2/(1.0f+ epsilonsq);
  } while (greject < rndm.z);

  // Scattered gamma angles
  if (sint2 < 0.0f) sint2 = 0.0f;
  costheta = 1.0f - onecost;
  sintheta = sqrt(sint2);
  phi = KissUniform(random, index_particle) * TWO_PI;

  // Update scattered gamma
  GGfloat3 gamma_direction = {sintheta*cos(phi), sintheta*sin(phi), costheta};
  gamma_direction = RotateUnitZ(gamma_direction, kGammaDirection);
  gamma_direction = GGfloat3UnitVector(gamma_direction);
  GGfloat const kE1 = kE0*epsilon;

  #ifdef GGEMS_TRACKING
  if (index_particle == primary_particle->particle_tracking_id) {
    printf("[GGEMS OpenCL function KleinNishinaComptonSampleSecondaries]     Scattered photon energy: %e keV\n", kE1/keV);
    printf("[GGEMS OpenCL function KleinNishinaComptonSampleSecondaries]     Scattered photon direction: %e %e %e\n", gamma_direction.x, gamma_direction.y, gamma_direction.z);
  }
  #endif

  primary_particle->E_[index_particle] = kE1;

  if (kE1 > 1.0e-06f) {
    primary_particle->dx_[index_particle] = gamma_direction.x;
    primary_particle->dy_[index_particle] = gamma_direction.y;
    primary_particle->dz_[index_particle] = gamma_direction.z;
  }
  else {
    primary_particle->status_[index_particle] = DEAD;
  }

  // Add kinematic of electron !!!!
}

#endif

#endif // GUARD_GGEMS_PHYSICS_GGEMSCOMPTONSCATTERINGMODELS_HH