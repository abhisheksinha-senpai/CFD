#include "ausmPlus.h"
#include <math.h>
#include <algorithm>
#include <stdio.h>

__global__ void pressureFlux(cell *domain, double *R, double *gammma, double M_inf)
{
	int y=threadIdx.x;
	int x=blockIdx.x;
	int ourFlag=(int)domain[x].flag;
	if(ourFlag==0 || ourFlag==4)
	{


		//Calculating the critical speed of sound for all the four sides/faces and the element itself
		double a_s[2];

		//Element
		a_s[0]=sqrt((2*(gammma[0]-1)/(gammma[0]+1))*(domain[x].stateVar[3]+(gammma[0]-1)*(domain[x].stateVar[3]-0.5*(pow(domain[x].stateVar[1],2)+pow(domain[x].stateVar[2],2))/domain[x].stateVar[0]))/domain[x].stateVar[0]);
		//Side/face
		a_s[1]=sqrt((2*(gammma[0]-1)/(gammma[0]+1))*(domain[x].temp_var[y][3]+(gammma[0]-1)*(domain[x].temp_var[y][3]-0.5*(pow(domain[x].temp_var[y][1],2)+pow(domain[x].temp_var[y][2],2))/domain[x].temp_var[y][0]))/domain[x].temp_var[y][0]);
		
		//speed for the boundary calculation
		a_s[0]=pow(a_s[0],2)/max(a_s[0],abs(sqrt(pow(domain[x].stateVar[1]/domain[x].stateVar[0],2)+pow(domain[x].stateVar[2]/domain[x].stateVar[0],2))));
		a_s[1]=pow(a_s[1],2)/max(a_s[1],abs(sqrt(pow(domain[x].temp_var[y][1]/domain[x].temp_var[y][0],2)+pow(domain[x].temp_var[y][2]/domain[x].temp_var[y][0],2))));

		//Speed of sound at facial interface
		double a_mid=min(a_s[0],a_s[1]);

		//Mach number of incoming and outgoing waves
		double mach_one=(domain[x].stateVar[1]/domain[x].stateVar[0]*domain[x].norms[y][0]+domain[x].stateVar[2]/domain[x].stateVar[0]*domain[x].norms[y][1])/a_mid;
		double mach_two=(domain[x].temp_var[y][1]/domain[x].temp_var[y][0]*domain[x].norms[y][0]+domain[x].temp_var[y][2]/domain[x].temp_var[y][0]*domain[x].norms[y][1])/a_mid;
		
		//Pressure Fluxes
		double press_one=(*gammma-1)*(domain[x].stateVar[3]-0.5*(pow(domain[x].stateVar[1],2)+pow(domain[x].stateVar[2],2))/domain[x].stateVar[0]);
		double press_two=(*gammma-1)*(domain[x].temp_var[y][3]-0.5*(pow(domain[x].temp_var[y][1],2)+pow(domain[x].temp_var[y][2],2))/domain[x].temp_var[y][0]);

		double one,two;
		if(abs(mach_one)>=1)
			one=0.5*(1+mach_one/abs(mach_one));
		else
			one=0.25*pow((mach_one+1),2)*(2-mach_one)+3/16*mach_one*pow((pow(mach_one,2)-1),2);
	
		if(abs(mach_two)>=1)
			two=0.5*(1-mach_two/abs(mach_two));
		else
			two=0.25*pow((mach_two-1),2)*(2+mach_two)-3/16*mach_two*pow((pow(mach_two,2)-1),2);

		domain[x].presflux[y][0]=1/(*gammma*M_inf*M_inf)*(press_one*one+press_two*two)*domain[x].norms[y][0]*sqrt(pow(domain[x].nodes[y][0]-domain[x].nodes[(y+1)%4][0],2)\
			+pow(domain[x].nodes[y][1]-domain[x].nodes[(y+1)%4][1],2));
		domain[x].presflux[y][1]=1/(*gammma*M_inf*M_inf)*(press_one*one+press_two*two)*domain[x].norms[y][1]*sqrt(pow(domain[x].nodes[y][0]-domain[x].nodes[(y+1)%4][0],2)\
			+pow(domain[x].nodes[y][1]-domain[x].nodes[(y+1)%4][1],2));

		if(abs(0.25*(domain[x].nodes[0][0]+domain[x].nodes[1][0]+domain[x].nodes[2][0]+domain[x].nodes[3][0])-0.3748442233)<0.000001 && abs(0.25*(domain[x].nodes[0][1]+domain[x].nodes[1][1]+domain[x].nodes[2][1]+domain[x].nodes[3][1])-21.6161422729)<0.00001)
		{
			printf("current stateVar %5.14lf %5.14lf %5.14lf %5.14lf %d %d\n",domain[x].stateVar[0],domain[x].stateVar[1],domain[x].stateVar[2],domain[x].stateVar[3],x+1,y);
			printf("bagal stateVar %5.14lf %5.14lf %5.14lf %5.14lf %d %d\n",domain[x].temp_var[y][0],domain[x].temp_var[y][1],domain[x].temp_var[y][2],domain[x].temp_var[y][3],(int)domain[x].face[y],y);
			printf("speed of sound (%5.14lf) flux (%5.14lf %5.14lf) %d %d\n",a_mid,domain[x].presflux[y][0],domain[x].presflux[y][1],x+1,y);	
		}
	}
}