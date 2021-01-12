// gcc process.c -I/usr/local/include -lmongoc-1.0 -lbson-1.0
// ./a.out 

#include <mongoc/mongoc.h>
#include <bson/bson.h>
#include <math.h>
#include "queue.h"
#include "data_struct.h"
#include "part.h"
#include "cluster.h"
#include "represent.h"
#include "connect.h"

#define laScale 111000.0
#define lgScale 85390.0

#define LOCNUM 300 // now about 20
#define TRAJNUM 1000 // now 74
#define LINESEGNUM 1000000 // now 3330

void get_locs (mongoc_collection_t *collection, loc_t *locs, int *locs_size);
void get_trajs (mongoc_collection_t *collection, traj_t *trajs, int *trajs_size);

void get_locs (mongoc_collection_t *collection, loc_t *locs, int *locs_size) {
    const bson_t *doc;
    bson_t *query = bson_new();
    mongoc_cursor_t *cursor = mongoc_collection_find_with_opts (collection, query, NULL, NULL);
    
    while (mongoc_cursor_next(cursor, &doc)) {
        // For a location
        bson_iter_t iter;
        const bson_value_t *value;
        const char *key;

        if (bson_iter_init(&iter, doc)) {
            while (bson_iter_next(&iter)) {
                key = bson_iter_key(&iter);
                value = bson_iter_value(&iter);

                if (strcmp(key, "name_en") == 0) {
                    strcpy(locs[*locs_size].name, value->value.v_utf8.str);
                } else if (strcmp(key, "latitude") == 0) {
                    locs[*locs_size].lat = value->value.v_double;
                } else if (strcmp(key, "longitude") == 0) {
                    locs[*locs_size].lng = value->value.v_double;
                } else if (strcmp(key, "altitude") == 0) {
                    locs[*locs_size].alt = value->value.v_double;
                } else if (strcmp(key, "type") == 0) {
                    locs[*locs_size].type = value->value.v_int64;
                }
            }
        }
        *locs_size = *locs_size + 1;
    }
}

void get_trajs (mongoc_collection_t *collection, traj_t *trajs, int *trajs_size) {
    const bson_t *doc;
    mongoc_cursor_t *cursor = mongoc_collection_find_with_opts (collection, bson_new(), NULL, NULL);
    while (mongoc_cursor_next(cursor, &doc)) {
        bson_iter_t iter1;
        bson_iter_t iter2;
        bson_iter_t iter3;
        const bson_value_t *value;
        const char *key;

        // start to iterate
        if (bson_iter_init(&iter1, doc)) {

            // if has next trajectory
            while (bson_iter_next(&iter1)) {
                
                // if the key is "points"
                if (strcmp (bson_iter_key(&iter1), "points") == 0) {
                    bson_iter_recurse(&iter1, &iter2);

                    // if has next point
                    int points_num = 0;
                    while (bson_iter_next(&iter2)) {
                        bson_iter_recurse(&iter2, &iter3);
                        
                        // for {latitude, longitude, altitude} of a point
                        while (bson_iter_next(&iter3)) {
                            key = bson_iter_key(&iter3);
                            value = bson_iter_value(&iter3);
                            if (strcmp(key, "latitude") == 0) {
                                trajs[*trajs_size].points[points_num].lat = value->value.v_double;
                            } else if (strcmp(key, "longitude") == 0) {
                                trajs[*trajs_size].points[points_num].lng = value->value.v_double;
                            } else if (strcmp(key, "altitude") == 0) {
                                trajs[*trajs_size].points[points_num].alt = value->value.v_double;
                            }
                        }
                        points_num ++;
                        
                    }
                    trajs[*trajs_size].points_num = points_num;
                    *trajs_size = *trajs_size + 1;
                }
            }
        }
    }
}


int main (int argc, char *argv[]) {
    /*
     *  Aim: connect to mongoDB.
     */
    mongoc_client_t *client;
    mongoc_database_t *database;
    mongoc_collection_t *collection;

    mongoc_init(); // Initialize libmongoc
    
    client = mongoc_client_new("mongodb://localhost:27017"); // Create a new client instance
    if (!client) {
        return EXIT_FAILURE;
    }
    database = mongoc_client_get_database(client, "CUMap");

    /*
     *  Aim: get locations data in db.
     *  Data: locs, locs_size(num of locs).
     *  Test: OK.
     */
    collection = mongoc_client_get_collection(client, "CUMap", "locations");
    loc_t *locs = (loc_t*) malloc(sizeof(loc_t) * LOCNUM);
    int locs_size = 0;
    get_locs(collection, locs, &locs_size);


    /*
     *  Aim: get trajectories data in db.
     *  Data: trajs, trajs_size(num of trajs).
     *  Test: OK.
     */
    collection = mongoc_client_get_collection(client, "CUMap", "trajectories");
    traj_t *trajs = (traj_t*) malloc(sizeof(traj_t) * TRAJNUM);
    for (int i = 0; i < TRAJNUM; i++) {
        trajs[i].points = (coor_t*) malloc(sizeof(coor_t) * TRAJNUM);
    }
    int trajs_size = 0;
    get_trajs(collection, trajs, &trajs_size);


    /*
     *  Aim: partition trajs into line_segs.
     *  Data: cp(characteristic points), cp_num ->line_segs, line_segs_size.
     *  Test: OK. By verifying the num of line_segs.
     */
    line_seg_t* line_segs = (line_seg_t*) malloc(sizeof(line_seg_t) * LINESEGNUM);
    int line_segs_size = 0;
    
    for (int traj_index = 0; traj_index < trajs_size; traj_index++) {
        if (trajs[traj_index].points_num < 2) {
            continue;
        }

        coor_t* cp = (coor_t*) malloc(sizeof(coor_t) * (trajs[traj_index].points_num + 1));
        int cp_num = 0;
        
        partition_traj(trajs[traj_index].points, trajs[traj_index].points_num, cp, &cp_num);
        
        for (int cp_index = 0; cp_index < cp_num - 1; cp_index ++) {
            line_segs[line_segs_size].start = cp[cp_index];
            line_segs[line_segs_size].end = cp[cp_index+1];
            line_segs[line_segs_size].cluster_id = 0;
            line_segs_size++;
        }
    }
    
    /*
     *  Aim: cluster line_segs by assigning cluster_id to them.
     *  Data: cluster_num.
     *  Test: OK. By verifying the num of cluster.
     */

    int cluster_num = 0;
    cluster(line_segs, line_segs_size, &cluster_num);


    /*
     *  Aim: generate rep_trajs from line_segs.
     *  Data: 
     *  Test: result dismatch.
     */
    int rep_trajs_size = 0;
    traj_t* rep_trajs = (traj_t*) malloc(sizeof(traj_t) * TRAJNUM);

    // assign line_segs to each line_segs_clusters
    line_segs_cluster_t* clusters = (line_segs_cluster_t*) malloc(sizeof(line_segs_cluster_t) * cluster_num);
    for (int i = 0; i < cluster_num; i++) {
        clusters[i].line_segs = (line_seg_t*) malloc(sizeof(line_seg_t) * line_segs_size);
        clusters[i].line_segs_size = 0;
    }

    for (int i = 0; i < line_segs_size; i++) {
        if (line_segs[i].cluster_id != -1 && line_segs[i].cluster_id != 0) {
            int index = clusters[line_segs[i].cluster_id - 1].line_segs_size;
            clusters[line_segs[i].cluster_id - 1].line_segs[index] = line_segs[i];
            clusters[line_segs[i].cluster_id - 1].line_segs_size = index + 1;
        }
    }
    
    // for each line_segs_clusters, generate rep_traj for it
    for (int i = 0; i < cluster_num; i++) {
        coor_t* represent = (coor_t*) malloc(sizeof(coor_t) * clusters[i].line_segs_size * 2);
        int represent_size = 0;
        generate_represent(clusters[i].line_segs, clusters[i].line_segs_size, represent, &represent_size);
        
        if (represent_size >= 2) {
            rep_trajs[rep_trajs_size].points = represent;
            rep_trajs[rep_trajs_size].points_num = represent_size;
            rep_trajs_size += 1;
        }
    }


    smooth(rep_trajs, &rep_trajs_size);

    /*for (int i = 0; i < rep_trajs_size; i++) {
        printf("%d\n", rep_trajs[i].points_num);
    }*/


    // test 
    /*for (int i = 0; i < rep_trajs_size; i++) {
        for (int j = 0; j < rep_trajs[i].points_num; j++) {
            printf("%f, %f, %f\n", rep_trajs[i].points[j].lat, rep_trajs[i].points[j].lng, rep_trajs[i].points[j].alt);
        }
    }*/
    

    // Release
    mongoc_database_destroy(database);
    mongoc_client_destroy(client);
    mongoc_cleanup();
    
    return 0;
}



