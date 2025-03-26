import pandas as pd

with open('4carlos.txt', 'r') as f:
    head = f.readline()
names = head.split()
names = names + ['BLA']

df = pd.read_csv('4carlos.txt', delimiter='<\|>', skiprows=1, names=names)
df['PROCESSING_VE'] = df['BLA']
del df['BLA']

df['START_TIME'] = pd.to_datetime(df['START_TIME'], dayfirst=True)
df['STOP_TIME'] = pd.to_datetime(df['STOP_TIME'], dayfirst=True)
df['ARCHIVE_DATE'] = pd.to_datetime(df['ARCHIVE_DATE'].str.replace('\s+',''), dayfirst=True, errors='coerce')
df['ORIG_OBSID'] = df['ORIG_OBSID'].apply(lambda s:'{:011d}'.format(s))
df['OBSID'] = df['OBSID'].apply(lambda s:'{:011d}'.format(s))

df_obj = df.select_dtypes(['object'])
df[df_obj.columns] = df_obj.apply(lambda x:x.str.replace('\s+',''))

df.to_csv('SwiftXrt_master_Sep2018.csv', sep=';', index=None, date_format='%d/%m/%Y', float_format='%.5f')
