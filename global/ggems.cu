 // This file is part of GGEMS
//
// GGEMS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// GGEMS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with GGEMS.  If not, see <http://www.gnu.org/licenses/>.
//
// GGEMS Copyright (C) 2013-2014 Julien Bert

#ifndef GGEMS_CU
#define GGEMS_CU

#include "ggems.cuh"

///////// Simulation Builder class ////////////////////////////////////////////////

SimulationBuilder::SimulationBuilder() {
    target = CPU_DEVICE;

    // Init physics list and secondaries list
    unsigned int i = 0;
    while (i < NB_PROCESSES) {
        parameters.physics_list[i] = DISABLED;
        ++i;
    }
    i = 0;
    while (i < NB_PARTICLES) {
        parameters.secondaries_list[i] = DISABLED;
        ++i;
    }

    parameters.dose_flag = DISABLED;
}

////// :: Main functions ::

// Generate particle based on the sources (CPU version)
void SimulationBuilder::cpu_primaries_generator() {

    // Loop over particle slot
    unsigned int id = 0;
    unsigned int is = 0;
    while (id < particles.stack.size) {

        // TODO - Generic and multi-sources
        //      Read CDF sources
        //      Rnd sources
        is = 0; // first source

        // Read the address source
        unsigned int adr = sources.sources.ptr_sources[is];

        // Read the kind of sources
        unsigned int type = (unsigned int)(sources.sources.data_sources[adr]);

        // Point Source
        if (type == POINT_SOURCE) {
            unsigned int geom_id = (unsigned int)(sources.sources.data_sources[adr+1]);
            float px = sources.sources.data_sources[adr+2];
            float py = sources.sources.data_sources[adr+3];
            float pz = sources.sources.data_sources[adr+4];
            float energy = sources.sources.data_sources[adr+5];

            point_source_primary_generator(particles.stack, id, px, py, pz, energy, PHOTON, geom_id);
        }

        // Next particle
        ++id;

    } // i

}

// Main navigation on CPU
void SimulationBuilder::cpu_main_navigation() {

    //cpu_main_navigator(particles, geometry, materials, parameters);

}

////// :: Setting ::


// Set the geometry of the simulation
void SimulationBuilder::set_geometry(GeometryBuilder obj) {
    geometry = obj;
}

// Set the materials definition associated to the geometry
void SimulationBuilder::set_materials(MaterialBuilder tab) {
    materials = tab;
}

// Set the particles stack
void SimulationBuilder::set_particles(ParticleBuilder p) {
    particles = p;
}

// Set the list of sources
void SimulationBuilder::set_sources(SourceBuilder src) {
    sources = src;
}

// Set the hardware used for the simulation CPU or GPU (CPU by default)
void SimulationBuilder::set_hardware_target(std::string value) {
    if (value == "GPU") {
        target = GPU_DEVICE;
    } else {
        target = CPU_DEVICE;
    }
}

// Add a process to the physics list
void SimulationBuilder::set_process(std::string process_name) {

    if (process_name == "Compton") {
        parameters.physics_list[PHOTON_COMPTON] = ENABLED;
        // printf("add Compton\n");
    } else if (process_name == "PhotoElectric") {
        parameters.physics_list[PHOTON_PHOTOELECTRIC] = ENABLED;
        // printf("add photoelectric\n");
    } else if (process_name == "eIonisation") {
        parameters.physics_list[ELECTRON_IONISATION] = ENABLED;
        // printf("add photoelectric\n");
    } else if (process_name == "eBremsstrahlung") {
        parameters.physics_list[ELECTRON_BREMSSTRAHLUNG] = ENABLED;
        // printf("add photoelectric\n");
    } else if (process_name == "eMultipleScattering") {
        parameters.physics_list[ELECTRON_MSC] = ENABLED;
        // printf("add photoelectric\n");
    } else {
        print_warning("This process is unknow!!\n");
        printf("     -> %s\n", process_name.c_str());
        exit_simulation();
    }
}

// Enable the simulation of a particular secondary particle
void SimulationBuilder::set_secondary(std::string pname) {

    if (pname == "Photon") {
        parameters.secondaries_list[PHOTON] = ENABLED;
        // printf("add Compton\n");
    } else if (pname == "Electron") {
        parameters.secondaries_list[ELECTRON] = ENABLED;
        // printf("add photoelectric\n");
    } else {
        print_warning("Secondary particle type is unknow!!");
        printf("     -> %s\n", pname.c_str());
        exit_simulation();
    }
}

// Set the number of particles required for the simulation
void SimulationBuilder::set_number_of_particles(unsigned int nb) {
    nb_of_particles = nb;
}

// Set the maximum number of iterations (watchdog)
void SimulationBuilder::set_max_number_of_iterations(unsigned int nb) {
    max_iteration = nb;
}

// Init simualtion
void SimulationBuilder::init_simulation() {

    // First compute the number of iterations and the size of a stack // TODO Can be improved - JB
    if (nb_of_particles % particles.stack.size) {
        nb_of_iterations = (nb_of_particles / particles.stack.size) + 1;
    } else {
        nb_of_iterations = nb_of_particles / particles.stack.size;
    }
    particles.stack.size = nb_of_particles / nb_of_iterations;
    nb_of_particles = particles.stack.size * nb_of_iterations;

    /*
    // Reset and set GPU ID and compute grid size
    wrap_reset_device();
    wrap_set_device(m_gpu_id);
    m_grid_size = (m_stack_size + m_block_size - 1) / m_block_size;

    // copy data to the device
    wrap_copy_phantom_to_device(h_phantom, d_phantom);
    wrap_copy_materials_to_device(h_materials, d_materials);

    // init particle stack
    wrap_init_particle_stack(d_particles, m_stack_size);

    // init particle seeds
    wrap_init_particle_seeds(d_particles, m_seed);

    // copy the physics list to the device
    wrap_copy_physics_list_to_device(m_physics_list);

    // copy the secondaries list to the device
    wrap_copy_secondaries_list_to_device(m_secondaries_list);
    */

    if (target == CPU_DEVICE) {

        // Init the particle stack
        particles.cpu_malloc_stack();
        particles.init_stack_seed();

    }
}

// Start the simulation
void SimulationBuilder::start_simulation() {

    // First init the simulation
    init_simulation();

    unsigned int iter = 0;

    if (target == CPU_DEVICE) {

        // Main loop
        while (iter < nb_of_iterations) {
            // Sources
            cpu_primaries_generator();

            // Locate the first particle position within the geometry

            // Navigation
            cpu_main_navigation();

            // iter
            ++iter;
            printf(">>> Iter %i / %i\n", iter, nb_of_iterations);
        } // main loop








    }

}








#endif
