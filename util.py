import os

def createDirAndOpen(f, m):
    (d, name) = os.path.split(f)
    if not os.path.exists(d):
        os.makedirs(d)
    return open(f, m)

## for camelcase preservation
def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])
def decapitalize(s):
    return '%s%s' % (s[0].lower(), s[1:])

