$# pyexpander macros  for Fixed Point operations

$py(        

def FLOAT_TO_FIXED(v):        
    return "%d" % (v * 16)
def FIXED_TO_INT(v):        
    return "(%s >> 4)" % (v)
def INT_TO_FIXED(v):        
    return "(%s << 4)" % (v)

FIXED = 'int'
FIXED_BITS = '4'
    )\

$extend(FLOAT_TO_FIXED)\
$extend(FIXED_TO_INT)\
$extend(INT_TO_FIXED)\

$extend(FIXED)\
$extend(FIXED_BITS)\



