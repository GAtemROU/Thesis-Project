import pandas as pd
import pprint as pp

from gen_trials import gen_simple_trials, gen_complex_trials, gen_unambiguous_trials

pp = pp.PrettyPrinter(sort_dicts=False)

simple_trials = gen_simple_trials()
complex_trials = gen_complex_trials()
unambiguous_trials = gen_unambiguous_trials()


final_simple = []
final_complex = []
final_unambiguous = []

counter = 1
for i in range(len(simple_trials)):
    if (i % 12 == 0):
        final_simple.append(simple_trials[i])
        final_simple.append(simple_trials[i+counter])
        final_complex.append(complex_trials[i])
        final_complex.append(complex_trials[i+counter])
        final_unambiguous.append(unambiguous_trials[i])
        final_unambiguous.append(unambiguous_trials[i+counter])
        counter+=2

for i in range(len(final_simple)):
    final_simple[i]['type'] = 'simple'
    final_complex[i]['type'] = 'complex'
    final_unambiguous[i]['type'] = 'unambiguous'



trials = final_simple + final_complex + final_unambiguous

df = pd.DataFrame(trials)
df['trial_id'] = range(1, len(df) + 1)
new_order = ['trial_id', 'type', 'sent_msg', 'trgt', 'comp', 'dist', 'msgs']
df = df.reindex(columns=new_order)
df.to_csv('trials/inputdata.csv', index=False)

# pp.pprint(df)