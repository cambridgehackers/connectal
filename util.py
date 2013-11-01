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

## things I thought would have been in functools (mdk)
intersperse = lambda e,l: sum([[x, e] for x in l],[])[:-1]
def foldl(f, x, l):
    if len(l) == 0:
        return x
    return foldl(f, f(x, l[0]), l[1:])
