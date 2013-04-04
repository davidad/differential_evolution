#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define PRINT_DOTS
#define PRINT_NEWBEST
//#define PRINT_MOVEMENTS
#define PRINT_FINAL_ANSWER

typedef double (*objective_fn)(void* object);
typedef void (*guess_fn)(double* vector, size_t N);

void unibox_guess(double* v, size_t N) {
    int i;
    for(i=0;i<N;i++) {
        v[i] = drand48();
    }
}

void print_vec(double* v, size_t N) {
    int i;
    printf("[ ");
    for(i=0;i<N;i++) {
        printf("%-10.5g ",v[i]);
    }
    printf("]");
}

double differential_evolution(double* result, size_t N, objective_fn f, double F, double CR, int NP, guess_fn guess, int iters) {
    if(!(F >= 0 && F <= 2)) {
        F = 1.0;
    }
    if(!(CR >= 0 && CR <= 1)) {
        CR = 0.8;
    }
    if(NP < 4) {
        NP = 4;
    }
    if(guess == NULL) {
        guess = unibox_guess;
    }
    double* xs = malloc(sizeof(double)*N*NP);
    int i;
    for(i=0;i<NP;i++) {
        guess(xs+(i*N),N);
    }
    double bestf = INFINITY;
    int bestx = 0;
    double fs[NP];
    for(i=0;i<NP;i++) {
        fs[i] = f(xs+i*N);
    }
    do {
        int x;
        for(x=0;x<NP;x++) {
            double *xp = xs+x*N;
            int a,b,c;
            do { a = lrand48() % NP; } while(a == x);
            do { b = lrand48() % NP; } while(b == x || b == a);
            do { c = lrand48() % NP; } while(c == x || c == a || c == b);
            int R = lrand48() % N;
            double y[N];
            for(i=0; i<N; i++) {
               double r = drand48();
               if(r < CR || i == R) {
                   y[i] = xs[a*N+i] + F*(xs[b*N+i] - xs[c*N+i]);
               } else {
                   y[i] = xp[i];
               }
            }
            double fy = f(y);
            double fx = fs[x];
            if(fy < fx) {
#ifdef PRINT_MOVEMENTS
                printf("Moving #%d from ",x);
                print_vec(xp,N);
                printf(" (f: %e) to ", fx);
                print_vec(y,N);
                printf(" (f: %e)\n", fy);
#endif
                memcpy(xp,y,sizeof(double)*N);
                fs[x] = fy;
                if(fy < bestf) {
                    bestf = fy;
                    bestx = x;
#ifdef PRINT_NEWBEST
                    printf("\nNew best f(x): %e ",bestf);
                    print_vec(xp,N);
                    printf("\n");
#endif
                }
            }
        }
    } while(--iters);
    memcpy(result,xs+bestx*N,sizeof(double)*N);
    return bestf;
}

double tgt[] = {1.0, -2.0, 3.0, -4.0, 5.0, -6.0, 7.0, -8.0};
size_t N = sizeof(tgt)/sizeof(double);

int total_f_evals = 0;

double test_f(void* o) {
    total_f_evals++;
#ifdef PRINT_DOTS
    printf(".");
#endif
    double* v = (double*)o;
    int i;
    double acc = 0.0;
    for(i=0; i<N; i++) {
        double diff = v[i] - tgt[i];
        acc += diff*diff;
    }
    return acc;
}

int main(int argc, char** argv) {
    int iters = 1e2;
    double F=1.0, CR=0.0, NP=40;
    if(argc>1) {
        iters = atoi(argv[1]);
        if(argc>2) {
            NP = atoi(argv[2]);
            if(argc>3) {
                CR = atof(argv[3]);
                if(argc>4) {
                    F = atof(argv[4]);
                }}}}

    srand48(time(NULL));
    double result[N];   
    double bestf = differential_evolution(result, N, test_f, F, CR, NP, NULL, iters);
#ifdef PRINT_FINAL_ANSWER
    printf("\nFINAL X  f(X): %e ",bestf);
    print_vec(result,N);
    printf("\nwith %d function evaluations\n", total_f_evals);
#endif
    return 0;
}
