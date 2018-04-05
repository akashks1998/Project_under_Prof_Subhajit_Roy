#include <nvgraph.h>
#include <bits/stdc++.h>
#define ROOT_TWO sqrt(2)
using namespace std;
///////////////////////////////////////////////////
void check(nvgraphStatus_t status) {
        if (status != NVGRAPH_STATUS_SUCCESS) {
                printf("ERROR : %d\n", status);
                exit(0);
        }
}
#define ROW 500
#define COL 4000
float* time_finder(float *slow,int _N,int _M) {
        int n=(_N+1)*(_M+1), vertex_numsets = 1, edge_numsets = 1, nnz=(_N *( _M +1)+(_N+1)*_M+ _M * _N*2)*2; //nnz=edges*2;
        float *weights_h=new float[nnz];
        int *destination_offsets_h=new int[n+1];
        int *source_indices_h=new int[nnz];
        int count=0;
        for(int i=0; i<= _N; i++) {
                for(int j=0; j<= _M; j++) {
                        int index=i*(_M+1)+j;
                        destination_offsets_h[index]=count;
                        int i_m,i_p,j_m,j_p;
                        i_m=(i-1>0 ? i-1 : 0);
                        i_p=(i>_N-1 ? _N-1 : i);
                        j_m=(j-1>0 ? j-1 : 0);
                        j_p=(j>_M-1 ? _M-1 : j);
                        //case 1
                        if(i>0) {
                                //case 1.1
                                if(j>0) {
                                        weights_h[count]= ROOT_TWO * slow[ i_m*(_M+1) + j_m];
                                        source_indices_h[count]=(i_m)*(_M+1)+j_m;
                                        count++;
                                }
                                //case 1.2
                                weights_h[count]=(slow[i_m*(_M+1) + j_m]+slow[i_m*(_M+1) + j_p])/2.0;
                                source_indices_h[count]=(i_m)*(_M+1)+j;
                                count++;
                                //case 1.3
                                if(j<_M) {
                                        weights_h[count]= ROOT_TWO * slow[(i-1)*(_M+1) + j];
                                        source_indices_h[count]=(i_m)*(_M+1)+j+1;
                                        count++;
                                }
                        }
                        //case 2
                        //case 2.1
                        if(j>0) {
                                weights_h[count]=(slow[i_m*(_M+1) + j_m]+slow[i_p*(_M+1) +j_m])/2.0;
                                source_indices_h[count]=(i_p)*(_M+1)+j_m;
                                count++;
                        }
                        //case 2.2
                        if(j<_M) {
                                weights_h[count]=(slow[i_m*(_M+1) + j_p]+slow[i_p*(_M+1) + j_p])/2.0;
                                source_indices_h[count]=(i)*(_M+1)+j+1;
                                count++;
                        }
                        //case 3
                        if(i<_N) {
                                //case 3.1
                                if(j>0) {
                                        weights_h[count]= ROOT_TWO * slow[i*(_M+1) + j-1];
                                        source_indices_h[count]=(i+1)*(_M+1)+j-1;
                                        count++;
                                }
                                //case 3.2
                                weights_h[count]=(slow[i_p*(_M+1) + j_m]+slow[i_p*(_M+1) + j_p])/2.0;
                                source_indices_h[count]=(i+1)*(_M+1)+j;
                                count++;
                                //case 3.3
                                if(j<_M) {
                                        weights_h[count]= ROOT_TWO * slow[i*(_M+1) + j];
                                        source_indices_h[count]=(i+1)*(_M+1)+j+1;
                                        count++;
                                }
                        }
                }
        }
        destination_offsets_h[n]=count;
        //Converting Adjacency Matrix in input to required input for nvgraph

        float * sssp_1_h;
        void * * vertex_dim; // nvgraph variables _h for host data.
        nvgraphStatus_t status;
        nvgraphHandle_t handle;
        nvgraphGraphDescr_t graph;
        nvgraphCSCTopology32I_t CSC_input;
        cudaDataType_t edge_dimT = CUDA_R_32F;
        cudaDataType_t * vertex_dimT;


        // Init host data
        /* *weights_h, *destination_offsets_h, *source_indices_h, n, nnz, vertex_numsets , edge_numsets already defined */
        sssp_1_h = new float[n];
        vertex_dim = new void*[vertex_numsets];
        vertex_dimT=new cudaDataType_t[vertex_numsets];
        CSC_input= (nvgraphCSCTopology32I_t) new nvgraphCSCTopology32I_t;
        vertex_dim[0] = (void * ) sssp_1_h;
        vertex_dimT[0] = CUDA_R_32F;


        check(nvgraphCreate( &handle));
        check(nvgraphCreateGraphDescr(handle, &graph));
        CSC_input->nvertices = n;
        CSC_input->nedges = nnz;
        CSC_input->destination_offsets = destination_offsets_h;
        CSC_input->source_indices = source_indices_h;
        check(nvgraphSetGraphStructure(handle, graph, (void * ) CSC_input, NVGRAPH_CSC_32));
        check(nvgraphAllocateVertexData(handle, graph, vertex_numsets, vertex_dimT));
        check(nvgraphAllocateEdgeData(handle, graph, edge_numsets, &edge_dimT));
        check(nvgraphSetEdgeData(handle, graph, (void * ) weights_h, 0));
        int source_vert = 0;
        check(nvgraphSssp(handle, graph, 0, &source_vert, 0));
        check(nvgraphGetVertexData(handle, graph, (void * ) sssp_1_h, 0));


        float* Actual_seed = new float[(_N+1)*(_M+1)];
        delete weights_h;
        delete destination_offsets_h;
        delete source_indices_h;
        delete vertex_dim;
        delete vertex_dimT;
        delete CSC_input;
        check(nvgraphDestroyGraphDescr(handle, graph));
        check(nvgraphDestroy(handle));
        return sssp_1_h;
}
int main(){
        float * inp;
        int n=ROW,m=COL;
        inp=new float[n*m];
        for(int i=0; i<n; i++) {
                for(int j=0; j<m; j++) {
                        inp[i*m+j]=1;
                }
        }
        float tpck[m+1];
        float* out=time_finder(inp,n,m);
        for(int i=0; i<m+1; i++) {
                tpck[i]=i;
        }
        float sum=0;
        for(int i=0; i<m+1; i++) {
                cout<<out[i]<<" ";
                sum=sum+(tpck[i]-out[i])*(tpck[i]-out[i]);
        }
        cout<<endl<<sum<<endl;
        return 0;
}
