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

#ifndef VOXELIZED_CU
#define VOXELIZED_CU

#include "voxelized.cuh"

Voxelized::Voxelized() {
    // Init pointer
    data = NULL;
}

// Skip comment starting with "#"
void Voxelized::skip_comment(std::istream & is) {
    i8 c;
    i8 line[1024];
    if (is.eof()) return;
    is >> c;
    while (is && (c=='#')) {
        is.getline(line, 1024);
        is >> c;
        if (is.eof()) return;
    }
    is.unget();
}

// Remove all white space
std::string Voxelized::remove_white_space(std::string txt) {
    txt.erase(remove_if(txt.begin(), txt.end(), isspace), txt.end());
    return txt;
}

// Read start range
f32 Voxelized::read_start_range(std::string txt) {
    f32 res;
    txt = txt.substr(0, txt.find(" "));
    std::stringstream(txt) >> res;
    return res;
}

// Read stop range
f32 Voxelized::read_stop_range(std::string txt) {
    f32 res;
    txt = txt.substr(txt.find(" ")+1);
    txt = txt.substr(0, txt.find(" "));
    std::stringstream(txt) >> res;
    return res;
}

// Read material range
std::string Voxelized::read_mat_range(std::string txt) {
    txt = txt.substr(txt.find(" ")+1);
    txt = txt.substr(txt.find(" ")+1);
    return txt.substr(0, txt.find(" "));
}

// Read mhd key
std::string Voxelized::read_mhd_key(std::string txt) {
    txt = txt.substr(0, txt.find("="));
    return remove_white_space(txt);
}

// Read string mhd arg
std::string Voxelized::read_mhd_string_arg(std::string txt) {
    txt = txt.substr(txt.find("=")+1);
    return remove_white_space(txt);
}

// Read i32 mhd arg
i32 Voxelized::read_mhd_int(std::string txt) {
    i32 res;
    txt = txt.substr(txt.find("=")+1);
    txt = remove_white_space(txt);
    std::stringstream(txt) >> res;
    return res;
}

// Read int mhd arg
i32 Voxelized::read_mhd_int_atpos(std::string txt, i32 pos) {
    i32 res;
    txt = txt.substr(txt.find("=")+2);
    if (pos==0) {
        txt = txt.substr(0, txt.find(" "));
    }
    if (pos==1) {
        txt = txt.substr(txt.find(" ")+1);
        txt = txt.substr(0, txt.find(" "));
    }
    if (pos==2) {
        txt = txt.substr(txt.find(" ")+1);
        txt = txt.substr(txt.find(" ")+1);
    }
    std::stringstream(txt) >> res;
    return res;
}

// Read f32 mhd arg
f32 Voxelized::read_mhd_f32_atpos(std::string txt, i32 pos) {
    f32 res;
    txt = txt.substr(txt.find("=")+2);
    if (pos==0) {
        txt = txt.substr(0, txt.find(" "));
    }
    if (pos==1) {
        txt = txt.substr(txt.find(" ")+1);
        txt = txt.substr(0, txt.find(" "));
    }
    if (pos==2) {
        txt = txt.substr(txt.find(" ")+1);
        txt = txt.substr(txt.find(" ")+1);
    }
    std::stringstream(txt) >> res;
    return res;
}

/* TODO Remove this
// Give a name to this object
void Voxelized::set_object_name(std::string objname) {
    object_name = objname;
}
*/

// Convert range data into material ID
void Voxelized::define_materials_from_range(f32 *raw_data, std::string range_name) {

    f32 start, stop;
    std::string mat_name, line;
    ui32 i;
    f32 val;
    ui32 mat_index = 0;

    // Data allocation
    data = (f32*)malloc(number_of_voxels * sizeof(f32));

    // Read range file
    std::ifstream file(range_name.c_str());
    if(!file) { printf("Error, file %s not found \n", range_name.c_str()); exit(EXIT_FAILURE);}
    while (file) {
        skip_comment(file);
        std::getline(file, line);

        if (file) {
            start = read_start_range(line);
            stop  = read_stop_range(line);
            mat_name = read_mat_range(line);
            list_of_materials.push_back(mat_name);
            //printf("IND %i MAT %s \n", mat_index, mat_name.c_str());

            // build labeled phantom according range data
            i=0; while (i < number_of_voxels) {
                val = raw_data[i];
                if ((val==start && val==stop) || (val>=start && val<stop)) {
                    data[i] = mat_index;
                }
                ++i;
            } // over the volume

        } // new material range
        ++mat_index;

    } // read file

}

// Load phantom from binary data (f32)
void Voxelized::load_from_raw(std::string volume_name, std::string range_name,
                              i32 nx, i32 ny, i32 nz, f32 sx, f32 sy, f32 sz) {

    /////////////// First read the raw data from the phantom ////////////////////////

    number_of_voxels = nx*ny*nz;
    nb_vox_x = nx;
    nb_vox_y = ny;
    nb_vox_z = nz;
    spacing_x = sx;
    spacing_y = sy;
    spacing_z = sz;
    mem_size = sizeof(f32) * number_of_voxels;

    FILE *pfile = fopen(volume_name.c_str(), "rb");
    if (!pfile) {
        printf("Error when loading raw data file: %s\n", volume_name.c_str());
        exit(EXIT_FAILURE);
    }

    f32 *raw_data = (f32*)malloc(mem_size);
    fread(raw_data, sizeof(f32), number_of_voxels, pfile);

    fclose(pfile);

    /////////////// Then, convert the raw data into material id //////////////////////

    define_materials_from_range(raw_data, range_name);

    // Free memory
    free(raw_data);

    ///////////// Define a bounding box for this phantom //////////////////////////////

    f32 h_lengthx = nb_vox_x * spacing_x * 0.5f;
    f32 h_lengthy = nb_vox_y * spacing_y * 0.5f;
    f32 h_lengthz = nb_vox_z * spacing_z * 0.5f;

    xmin = -h_lengthx; xmax = h_lengthx;
    ymin = -h_lengthy; ymax = h_lengthy;
    zmin = -h_lengthz; zmax = h_lengthz;

}

// Load phantom from mhd file (only f32 data)
void Voxelized::load_from_mhd(std::string volume_name, std::string range_name) {

    /////////////// First read the MHD file //////////////////////

    std::string line, key;
    i32 nx=-1, ny=-1, nz=-1;
    f32 sx=0, sy=0, sz=0;

    // Watchdog
    std::string ObjectType="", BinaryData="", BinaryDataByteOrderMSB="", CompressedData="",
                ElementType="", ElementDataFile="";
    i32 NDims=0;

    // Read range file
    std::ifstream file(volume_name.c_str());
    if(!file) { printf("Error, file %s not found \n", volume_name.c_str()); exit(EXIT_FAILURE);}
    while (file) {
        skip_comment(file);
        std::getline(file, line);

        if (file) {
            key = read_mhd_key(line);
            if (key=="ObjectType")              ObjectType = read_mhd_string_arg(line);
            if (key=="NDims")                   NDims = read_mhd_int(line);
            if (key=="BinaryData")              BinaryData = read_mhd_string_arg(line);
            if (key=="BinaryDataByteOrderMSB")  BinaryDataByteOrderMSB=read_mhd_string_arg(line);
            if (key=="CompressedData")          CompressedData = read_mhd_string_arg(line);
            //if (key=="TransformMatrix") printf("Matrix\n");
            //if (key=="Offset")  printf("Offset\n");
            //if (key=="CenterOfRotation") printf("CoR\n");
            if (key=="ElementSpacing") {
                                                sx=read_mhd_f32_atpos(line, 0);
                                                sy=read_mhd_f32_atpos(line, 1);
                                                sz=read_mhd_f32_atpos(line, 2);
            }
            if (key=="DimSize") {
                                                nx=read_mhd_int_atpos(line, 0);
                                                ny=read_mhd_int_atpos(line, 1);
                                                nz=read_mhd_int_atpos(line, 2);
            }

            //if (key=="AnatomicalOrientation") printf("Anato\n");
            if (key=="ElementType")             ElementType = read_mhd_string_arg(line);
            if (key=="ElementDataFile")         ElementDataFile = read_mhd_string_arg(line);
        }

    } // read file

    // Check header
    if (ObjectType != "Image") {
        printf("Error, mhd header: ObjectType = %s\n", ObjectType.c_str());
        exit(EXIT_FAILURE);
    }
    if (BinaryData != "True") {
        printf("Error, mhd header: BinaryData = %s\n", BinaryData.c_str());
        exit(EXIT_FAILURE);
    }
    if (BinaryDataByteOrderMSB != "False") {
        printf("Error, mhd header: BinaryDataByteOrderMSB = %s\n", BinaryDataByteOrderMSB.c_str());
        exit(EXIT_FAILURE);
    }
    if (CompressedData != "False") {
        printf("Error, mhd header: CompressedData = %s\n", CompressedData.c_str());
        exit(EXIT_FAILURE);
    }
    if (ElementType != "MET_FLOAT") {
        printf("Error, mhd header: ElementType = %s\n", ElementType.c_str());
        exit(EXIT_FAILURE);
    }
    if (ElementDataFile == "") {
        printf("Error, mhd header: ElementDataFile = %s\n", ElementDataFile.c_str());
        exit(EXIT_FAILURE);
    }
    if (NDims != 3) {
        printf("Error, mhd header: NDims = %i\n", NDims);
        exit(EXIT_FAILURE);
    }

    if (nx == -1 || ny == -1 || nz == -1 || sx == 0 || sy == 0 || sz == 0) {
        printf("Error when loading mhd file (unknown dimension and spacing)\n");
        printf("   => dim %i %i %i - spacing %f %f %f\n", nx, ny, nz, sx, sy, sz);
        exit(EXIT_FAILURE);
    }
    // Read data
    FILE *pfile = fopen(ElementDataFile.c_str(), "rb");
    if (!pfile) {
        std::string nameWithRelativePath = volume_name;
        i32 lastindex = nameWithRelativePath.find_last_of(".");
        nameWithRelativePath = nameWithRelativePath.substr(0, lastindex);
        nameWithRelativePath+=".raw";
        pfile = fopen(nameWithRelativePath.c_str(), "rb");
        if (!pfile) {
            printf("Error when loading mhd file: %s\n", ElementDataFile.c_str());
            exit(EXIT_FAILURE);
        }
    }

    number_of_voxels = nx*ny*nz;
    nb_vox_x = nx;
    nb_vox_y = ny;
    nb_vox_z = nz;
    spacing_x = sx;
    spacing_y = sy;
    spacing_z = sz;
    mem_size = sizeof(f32) * number_of_voxels;

    f32 *raw_data = (f32*)malloc(mem_size);
    fread(raw_data, sizeof(f32), number_of_voxels, pfile);
    fclose(pfile);

    //printf("Size of MHD file  %u, nb of voxels %u \n",m_mem_size, m_nb_voxels);

    /////////////// Then, convert the raw data into material id //////////////////////

    define_materials_from_range(raw_data, range_name);

    // Free memory
    free(raw_data);

    ///////////// Define a bounding box for this phantom //////////////////////////////

    f32 h_lengthx = nb_vox_x * spacing_x * 0.5f;
    f32 h_lengthy = nb_vox_y * spacing_y * 0.5f;
    f32 h_lengthz = nb_vox_z * spacing_z * 0.5f;

    xmin = -h_lengthx; xmax = h_lengthx;
    ymin = -h_lengthy; ymax = h_lengthy;
    zmin = -h_lengthz; zmax = h_lengthz;

}

// Define which material to display in the viewer (VRML) and how
void Voxelized::set_color_map(std::string matname, Color col, f32 alpha) {
    show_mat.push_back(matname);
    show_colors.push_back(col);
    show_transparencies.push_back(alpha);
}

#endif






















