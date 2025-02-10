#!/bin/bash

read -p "Enter protein filename (.pdb): " filename
read -p "how many cpu cores do you have: " cores

# delete water molecule in the PDB file
grep -v HOH $filename > ${filename%.*}_clean.pdb

wait

# create files what we need for the next steps
# we will use the all-atom OPLS force field, so type 15
gmx pdb2gmx -f ${filename%.*}_clean.pdb -o ${filename%.*}_processed.gro -water spce

wait

#create a unit cell
gmx editconf -f ${filename%.*}_processed.gro -o ${filename%.*}_newbox.gro -c -d 10.0 -bt cubic

wait

# will fill the unit cell with the solvate water
gmx solvate -cp ${filename%.*}_newbox.gro -cs spc216.gro -o ${filename%.*}_solv.gro -p topol.top

wait

# create file what we need for the next step
gmx grompp -f ions.mdp -c ${filename%.*}_solv.gro -o ions.tpr -p topol.top

wait

# add ions in the PDB file
# when prompted, choose group 13 "SOL" for embedding ions
gmx genion -s ions.tpr -o ${filename%.*}_solv_ions.gro -p topol.top -nname CL -pname NA -neutral

wait

# create file what we need for the next step
gmx grompp -f minim.mdp -c ${filename%.*}_solv_ions.gro -o em.tpr -p topol.top

wait

# calculate
gmx mdrun -v -deffnm em -nt ${cores}

wait

# create a plot for the potential energy of the system by time
# type "10 0" at the prompt to select the potential energy of the system
gmx energy -f em.edr -o potential.xvg


wait

# create file what we need for the next step
gmx grompp -f nvt.mdp -c em.gro -r em.gro -o nvt.tpr -p topol.top

wait

# calculate
gmx mdrun -v -deffnm nvt -nt ${cores}

wait

# create a plot for the temperature of the system by time
# type "16 0" at the prompt to select the temperature of the system
gmx energy -f nvt.edr -o temperature.xvg


wait

# create file what we need for the next step
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -o npt.tpr -p topol.top


wait

# calculate
gmx mdrun -v -deffnm npt -nt ${cores}

wait

# create a plot for the pressure of the system by time
# type "18 0" at the prompt to select the pressure of the system
gmx energy -f npt.edr -o pressure.xvg


wait

# create a plot for the density of the system by time
# type "24 0" at the prompt to select the density of the system
gmx energy -f npt.edr -o density.xvg


wait

# create file what we need for the next step
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -o md.tpr -p topol.top

wait

# calculate
gmx mdrun -v -deffnm md -nt ${cores}



#congratulation, now you have md.pdb and md.xtc , with that you can run your simulation in software like VMD, ... 