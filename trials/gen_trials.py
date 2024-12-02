import itertools
import pprint

pp = pprint.PrettyPrinter(sort_dicts=False)

shapes = ['circle', 'square', 'triangle']
colors = ['red', 'green', 'blue']

simple_trials = []
complex_trials = []
id_to_obj = ['trgt', 'comp', 'dist']
                 # feature 1
             #trgt #comp #distr
simple_matrix = [[1, 1, 0], # sent msg
                 [0, 0, 0], # not available msg
                 [0, 0, 1],
                 # feature 2
                 [0, 0, 1],
                 [0, 1, 0],
                 [1, 0, 0]] # not available msg
available_msgs_ids_simple = [0, 2, 3, 4]

complex_matrix = [[1, 1, 0],
                  [0, 0, 1],
                  [0, 0, 0],
                  [0, 1, 0],
                  [1, 0, 1],
                  [0, 0, 0]]
available_msgs_ids_complex = [0, 1, 3, 4]
avaialble_msgs_ids_complexer = [0, 2, 3, 4]


def gen_trials(shapes, colors, matrix, available_msgs_ids, id_to_obj_type):
    trials = []
    msgs_len = len(shapes) + len(colors)
    shape_perms = list(itertools.permutations(shapes))
    color_perms = list(itertools.permutations(colors))
    for shape_perm in shape_perms:
        for color_perm in color_perms:
            feature1 = list(shape_perm)
            feature2 = list(color_perm)
            for colors_first in range(2):
                all_msgs_order = []
                if (colors_first):
                    all_msgs_order = feature2 + feature1
                else:
                    all_msgs_order = feature1 + feature2
                trial = {'sent_msg' : all_msgs_order[0]}
                for i in range(len(matrix)):
                    if not colors_first:
                        i = msgs_len-i-1
                    for j in range(len(matrix[i])):
                        if (matrix[i][j]):
                            if (i > (msgs_len/2)-1 and not colors_first) or (i < msgs_len/2 and colors_first):
                                trial[id_to_obj_type[j]] = all_msgs_order[i]
                            else:
                                trial[id_to_obj_type[j]] += '_' + all_msgs_order[i]
                msgs = [all_msgs_order[msg_id] for msg_id in available_msgs_ids]
                trial['msgs'] = msgs
                trials.append(trial)
    return trials

simple_trials = gen_trials(shapes, colors, simple_matrix, available_msgs_ids_simple, id_to_obj)
complex_trials = gen_trials(shapes, colors, complex_matrix, available_msgs_ids_complex, id_to_obj)

final_simple = []
final_complex = []

counter = 1
for i in range(len(simple_trials)):
    if (i % 12 == 0):
        final_simple.append(simple_trials[i])
        final_simple.append(simple_trials[i+counter])
        final_complex.append(complex_trials[i])
        final_complex.append(complex_trials[i+counter])
        counter+=2


pp.pprint(len(final_simple))
pp.pprint(final_simple)

pp.pprint(len(final_complex))
pp.pprint(final_complex)