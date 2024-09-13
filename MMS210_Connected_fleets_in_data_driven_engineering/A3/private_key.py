'''
import os
with open('vehicle_ids.txt','r') as f:
    ids = f.readlines()
    for id_i in ids:
        id_i = id_i.strip()
        print(f'The vehicle ID is {id_i}')
        os.system(f'curl -s --insecure -m 60  https://skyrator.fleet/vehicle/{id_i}/sensor/speed')
'''
        
import os

with open('vehicle_ids.txt','r') as f, open('output.txt', 'w') as f_out:
    ids = f.readlines()
    for id_i in ids:
        id_i = id_i.strip()
        f_out.write(f'The vehicle ID is {id_i}\n')
        print(f'The vehicle ID: {id_i}')
        os.system(f'curl -s --insecure -m 60  https://skyrator.fleet/vehicle/{id_i}/sensor/speed')
        output = os.popen(f'curl -s --insecure -m 60  https://skyrator.fleet/vehicle/{id_i}/sensor/speed').read()
        f_out.write(output + '\n')


