# -*- coding: utf-8 -*-
"""
    The Bsv domain.

    :copyright: Copyright 2007-2014 by the Sphinx team, see AUTHORS.
                Copyright 2014 Quanta Research Cambridge.
    :license: BSD, see LICENSE for details.
"""

from __future__ import print_function

import re

from docutils import nodes
from docutils.parsers.rst import directives

from sphinx import addnodes
from sphinx.roles import XRefRole
from sphinx.locale import l_, _
from sphinx.domains import Domain, ObjType, Index
from sphinx.directives import ObjectDescription
from sphinx.util.nodes import make_refnode
from sphinx.util.docutils import SphinxDirective
from sphinx.util.docfields import Field, GroupedField, TypedField


# REs for Bsv signatures
bsv_param_re = re.compile('^\((.*)\)$')

def _pseudo_parse_arglist(signode, arglist):
    """"Parse" a list of arguments separated by commas.

    Arguments can have "optional" annotations given by enclosing them in
    brackets.  Currently, this will split at any comma, even if it's inside a
    string literal (e.g. default argument value).
    """
    paramlist = addnodes.desc_parameterlist()
    stack = [paramlist]
    try:
        for argument in arglist.split(','):
            argument = argument.strip()
            ends_open = ends_close = 0
            while argument.startswith('['):
                stack.append(addnodes.desc_optional())
                stack[-2] += stack[-1]
                argument = argument[1:].strip()
            while argument.startswith(']'):
                stack.pop()
                argument = argument[1:].strip()
            while argument.endswith(']'):
                ends_close += 1
                argument = argument[:-1].strip()
            while argument.endswith('['):
                ends_open += 1
                argument = argument[:-1].strip()
            if argument:
                stack[-1] += addnodes.desc_parameter(argument, argument)
            while ends_open:
                stack.append(addnodes.desc_optional())
                stack[-2] += stack[-1]
                ends_open -= 1
            while ends_close:
                stack.pop()
                ends_close -= 1
        if len(stack) != 1:
            raise IndexError
    except IndexError:
        # if there are too few or too many elements on the stack, just give up
        # and treat the whole argument list as one argument, discarding the
        # already partially populated paramlist node
        signode += addnodes.desc_parameterlist()
        signode[-1] += addnodes.desc_parameter(arglist, arglist)
    else:
        signode += paramlist


class BsvObject(ObjectDescription):
    """
    Description of a general Bsv object.
    """
    option_spec = {
        'noindex': directives.flag,
        'package': directives.unchanged,
        'annotation': directives.unchanged,
        'parameter': directives.unchanged,
        'returntype': directives.unchanged,
    }

    doc_field_types = [
        TypedField('parameter', label=l_('Parameters'),
                   names=('param', 'parameter', 'arg', 'argument',
                          'keyword', 'kwarg', 'kwparam'),
                   typerolename='obj', typenames=('paramtype', 'type'),
                   can_collapse=True),
        TypedField('variable', label=l_('Variables'), rolename='obj',
                   names=('var', 'ivar', 'cvar'),
                   typerolename='obj', typenames=('vartype',),
                   can_collapse=True),
        GroupedField('exceptions', label=l_('Raises'), rolename='exc',
                     names=('raises', 'raise', 'exception', 'except'),
                     can_collapse=True),
        Field('returnvalue', label=l_('Returns'), has_arg=False,
              names=('returns', 'return')),
        Field('returntype', label=l_('Return type'), has_arg=False,
              names=('rtype',)),
    ]

    def get_signatures(self):
        siglines = ObjectDescription.get_signatures(self)
        return siglines

    def get_signature_prefix(self, sig):
        """May return a prefix to put before the object name in the
        signature.
        """
        return ''

    def needs_arglist(self):
        """May return true if an empty argument list is to be generated even if
        the document contains none.
        """
        return False

    def handle_signature(self, sig, signode):
        """Transform a Bsv signature into RST nodes.

        Return (fully qualified name of the thing, interfacename if any).

        If inside a interface, the current interface name is handled intelligently:
        * it is stripped from the displayed name if present
        * it is added to the full name (return value) if not present
        """
        print('BsvObject.handle_signature', sig)
        name_prefix = ''
        name = sig
        arglist = ''
        retann = ''
        if self.objtype in ['interface', 'instance', 'typeclass']:
            split = sig.split('#', 1)
            name = split[0]
            if len(split) > 1:
                arglist = split[1]
                m = bsv_param_re.match(arglist)
                if m: arglist = m.group(1)
        elif self.objtype in ['subinterface', 'field']:
            split = sig.rsplit(' ', 1)
            print('rsplit', split)
            name = split[-1]
            if len(split) > 1:
                retann = split[0]
        elif self.objtype in ['method', 'function']:
            split = sig.split(' ', 1)
            retann = split[0]
            nameparams = split[1]
            split = nameparams.split('(', 1)
            name = split[0]
            if len(split) > 1:
                arglist = split[1][0:-1]
        elif self.objtype in ['module']:
            split = sig.split('#', 1)
            name = split[0]
            if len(split) > 1:
                depth = 0
                paramreturn = split[1]
                #print('module', paramreturn, len(paramreturn))
                for i in range(0,len(paramreturn)):
                    c = paramreturn[i]
                    if c == '(': depth = depth+1
                    elif c == ')': depth = depth-1
                    
                    #print(i, c, depth)
                    if depth==0:
                        endofparam=i
                        break
                arglist = paramreturn[1:endofparam]
                retann = paramreturn[endofparam+1:-1]
                #print(arglist)
                #print(endofparam, retann)

        # determine package and interface name (if applicable), as well as full name
        modname = self.options.get(
            'package', self.env.temp_data.get('bsv:package'))
        interfacename = self.env.temp_data.get('bsv:interface')
        if interfacename:
            add_package = False
            if name_prefix and name_prefix.startswith(interfacename):
                fullname = name_prefix + name
                # interface name is given again in the signature
                name_prefix = name_prefix[len(interfacename):].lstrip('.')
            elif name_prefix:
                # interface name is given in the signature, but different
                # (shouldn't happen)
                fullname = interfacename + '.' + name_prefix + name
            else:
                # interface name is not given in the signature
                fullname = interfacename + '.' + name
        else:
            add_package = True
            if name_prefix:
                interfacename = name_prefix.rstrip('.')
                fullname = name_prefix + name
            else:
                interfacename = ''
                fullname = name

        signode['package'] = modname
        signode['interface'] = interfacename
        signode['fullname'] = fullname

        sig_prefix = self.get_signature_prefix(sig)
        if sig_prefix:
            signode += addnodes.desc_annotation(sig_prefix, sig_prefix)

        if name_prefix:
            signode += addnodes.desc_addname(name_prefix, name_prefix)
        # exceptions are a special case, since they are documented in the
        # 'exceptions' package.
        elif add_package and self.env.config.add_package_names:
            modname = self.options.get(
                'package', self.env.temp_data.get('bsv:package'))
            if modname and modname != 'exceptions':
                nodetext = modname + '::'
                signode += addnodes.desc_addname(nodetext, nodetext)

        anno = self.options.get('annotation')

        signode += addnodes.desc_name(name, name)
        #print('arglist', arglist)
        if not arglist:
            if self.needs_arglist():
                # for callables, add an empty parameter list
                if arglist:
                    signode += addnodes.desc_parameterlist(text=arglist)
                elif self.options.get('parameter'):
                    signode += addnodes.desc_parameterlist(text=self.options.get('parameter'))
            if retann:
                signode += addnodes.desc_returns(text=retann)
            elif self.options.get('returntype'):
                signode += addnodes.desc_returns(text=self.options.get('returntype'))
            if anno:
                signode += addnodes.desc_annotation(' ' + anno, ' ' + anno)
            #print('signode', signode)
            return fullname, name_prefix

        _pseudo_parse_arglist(signode, arglist)
        if retann:
            signode += addnodes.desc_returns(retann, retann)
        if anno:
            signode += addnodes.desc_annotation(' ' + anno, ' ' + anno)
        return fullname, name_prefix

    def get_index_text(self, modname, name):
        """Return the text for the index entry of the object."""
        raise NotImplementedError('must be implemented in subinterfacees')

    def add_target_and_index(self, name_cls, sig, signode):
        modname = self.options.get(
            'package', self.env.temp_data.get('bsv:package'))
        fullname = (modname and modname + '::' or '') + name_cls[0]
        # note target
        if fullname not in self.state.document.ids:
            signode['names'].append(fullname)
            signode['ids'].append(fullname)
            signode['first'] = (not self.names)
            self.state.document.note_explicit_target(signode)
            objects = self.env.domaindata['bsv']['objects']
            if fullname in objects:
                self.state_machine.reporter.warning(
                    'duplicate object description of %s, ' % fullname +
                    'other instance in ' +
                    self.env.doc2path(objects[fullname][0]) +
                    ', use :noindex: for one of them',
                    line=self.lineno)
            objects[fullname] = (self.env.docname, self.objtype)

        indextext = self.get_index_text(modname, name_cls)
        if indextext:
            self.indexnode['entries'].append(('single', indextext,
                                              fullname, ''))

    def before_content(self):
        # needed for automatic qualification of members (reset in subinterfacees)
        self.clsname_set = False

    def after_content(self):
        if self.clsname_set:
            self.env.temp_data['bsv:interface'] = None


class BsvPackagelevel(BsvObject):
    """
    Description of an object on package level (functions, data).
    """

    def get_signature_prefix(self, sig):
        return self.objtype + ' '

    def needs_arglist(self):
        return self.objtype.endswith('method') or self.objtype in ['typedef', 'function', 'interface', 'typeclass']

    def get_index_text(self, modname, name_cls):
        if modname:
            return _('%s (%s in package %s)') % (name_cls[0], self.objtype, modname)
        else:
            return _('%s (%s)') % (name_cls[0], self.objtype)


class BsvInterfacelike(BsvObject):
    """
    Description of a interface-like object (interfacees).
    """

    def get_signature_prefix(self, sig):
        return self.objtype + ' '

    def get_index_text(self, modname, name_cls):
        if modname:
            return _('%s (%s in package %s)') % (name_cls[0], self.objtype, modname)
        else:
            return _('%s (%s)') % (name_cls[0], self.objtype)

    def before_content(self):
        BsvObject.before_content(self)
        if self.names:
            self.env.temp_data['bsv:interface'] = self.names[0][0]
            self.clsname_set = True


class BsvInterfacemember(BsvObject):
    """
    Description of a interface member (methods, fields).
    """

    option_spec = {
        'noindex': directives.flag,
        'package': directives.unchanged,
        'annotation': directives.unchanged,
        'returntype': directives.unchanged_required,
        'parameter': directives.unchanged_required
        }

    def needs_arglist(self):
        return self.objtype.endswith('method') or self.objtype in ['typedef', 'interface', 'subinterface', 'field']

    def get_signature_prefix(self, sig):
        if self.objtype == 'staticmethod':
            return 'static '
        elif self.objtype == 'interfacemethod':
            return 'interfacemethod '
        return ''

    def get_index_text(self, modname, name_cls):
        name, cls = name_cls
        add_packages = self.env.config.add_package_names
        print('BsvInterfacemember.get_index_text', name, cls, modname)
        if self.objtype == 'method':
            try:
                clsname, methname = name.rsplit('.', 1)
            except ValueError:
                if modname:
                    return _('%s() (in package %s)') % (name, modname)
                else:
                    return '%s()' % name
            if modname and add_packages:
                return _('%s() (%s::%s method)') % (methname, modname, clsname)
            else:
                return _('%s() (%s method)') % (methname, clsname)
        elif self.objtype == 'staticmethod':
            try:
                clsname, methname = name.rsplit('.', 1)
            except ValueError:
                if modname:
                    return _('%s() (in package %s)') % (name, modname)
                else:
                    return '%s()' % name
            if modname and add_packages:
                return _('%s() (%s::%s static method)') % (methname, modname,
                                                          clsname)
            else:
                return _('%s() (%s static method)') % (methname, clsname)
        elif self.objtype == 'interfacemethod':
            try:
                clsname, methname = name.rsplit('.', 1)
            except ValueError:
                if modname:
                    return _('%s() (in package %s)') % (name, modname)
                else:
                    return '%s()' % name
            if modname:
                return _('%s() (%s::%s interface method)') % (methname, modname,
                                                         clsname)
            else:
                return _('%s() (%s interface method)') % (methname, clsname)
        elif self.objtype == 'attribute':
            try:
                clsname, attrname = name.rsplit('.', 1)
            except ValueError:
                if modname:
                    return _('%s (in package %s)') % (name, modname)
                else:
                    return name
            if modname and add_packages:
                return _('%s (%s::%s attribute)') % (attrname, modname, clsname)
            else:
                return _('%s (%s attribute)') % (attrname, clsname)
        else:
            return ''

    def before_content(self):
        BsvObject.before_content(self)
        lastname = self.names and self.names[-1][1]
        if lastname and not self.env.temp_data.get('bsv:interface'):
            self.env.temp_data['bsv:interface'] = lastname.strip('.')
            self.clsname_set = True


class BsvDecoratorMixin(object):
    """
    Mixin for decorator directives.
    """
    def handle_signature(self, sig, signode):
        print('BsvDecoratorMixin.handle_signature', sig)
        ret = super(BsvDecoratorMixin, self).handle_signature(sig, signode)
        signode.insert(0, addnodes.desc_addname('@', '@'))
        return ret

    def needs_arglist(self):
        return False


class BsvDecoratorFunction(BsvDecoratorMixin, BsvPackagelevel):
    """
    Directive to mark functions meant to be used as decorators.
    """
    def run(self):
        # a decorator function is a function after all
        self.name = 'bsv:function'
        return BsvPackagelevel.run(self)


class BsvDecoratorMethod(BsvDecoratorMixin, BsvInterfacemember):
    """
    Directive to mark methods meant to be used as decorators.
    """
    def run(self):
        self.name = 'bsv:method'
        return BsvInterfacemember.run(self)


class BsvPackage(SphinxDirective):
    """
    Directive to mark description of a new package.
    """

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {
        'platform': lambda x: x,
        'synopsis': lambda x: x,
        'noindex': directives.flag,
        'deprecated': directives.flag,
    }

    def run(self):
        env = self.state.document.settings.env
        modname = self.arguments[0].strip()
        noindex = 'noindex' in self.options
        env.temp_data['bsv:package'] = modname
        ret = []
        if not noindex:
            env.domaindata['bsv']['packages'][modname] = \
                (env.docname, self.options.get('synopsis', ''),
                 self.options.get('platform', ''), 'deprecated' in self.options)
            # make a duplicate entry in 'objects' to facilitate searching for
            # the package in BsvDomain.find_obj()
            env.domaindata['bsv']['objects'][modname] = (env.docname, 'package')
            targetnode = nodes.target('', '', ids=['package-' + modname],
                                      ismod=True)
            self.state.document.note_explicit_target(targetnode)
            # the platform and synopsis aren't printed; in fact, they are only
            # used in the pkgindex currently
            ret.append(targetnode)
            indextext = _('%s (package)') % modname
            inode = addnodes.index(entries=[('single', indextext,
                                             'package-' + modname, '')])
            ret.append(inode)
        return ret


class BsvCurrentPackage(SphinxDirective):
    """
    This directive is just to tell Sphinx that we're documenting
    stuff in package foo, but links to package foo won't lead here.
    """

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {}

    def run(self):
        env = self.state.document.settings.env
        modname = self.arguments[0].strip()
        if modname == 'None':
            env.temp_data['bsv:package'] = None
        else:
            env.temp_data['bsv:package'] = modname
        return []


class BsvXRefRole(XRefRole):
    def process_link(self, env, refnode, has_explicit_title, title, target):
        refnode['bsv:package'] = env.temp_data.get('bsv:package')
        refnode['bsv:interface'] = env.temp_data.get('bsv:interface')
        if not has_explicit_title:
            title = title.lstrip('.')   # only has a meaning for the target
            target = target.lstrip('~') # only has a meaning for the title
            # if the first character is a tilde, don't display the package/interface
            # parts of the contents
            if title[0:1] == '~':
                title = title[1:]
                dot = title.rfind('.')
                if dot != -1:
                    title = title[dot+1:]
        # if the first character is a dot, search more specific namespaces first
        # else search builtins first
        if target[0:1] == '.':
            target = target[1:]
            refnode['refspecific'] = True
        return title, target


class BsvPackageIndex(Index):
    """
    Index subinterface to provide the Bsv package index.
    """

    name = 'pkgindex'
    localname = l_('Bsv Package Index')
    shortname = l_('bsvpkgs')

    def generate(self, docnames=None):
        content = {}
        # list of prefixes to ignore
        ignores = self.domain.env.config['pkgindex_common_prefix']
        ignores = sorted(ignores, key=len, reverse=True)
        # list of all packages, sorted by package name
        packages = sorted(self.domain.data['packages'].items(),
                         key=lambda x: x[0].lower())
        # sort out collapsable packages
        prev_modname = ''
        num_toplevels = 0
        for modname, (docname, synopsis, platforms, deprecated) in packages:
            if docnames and docname not in docnames:
                continue

            for ignore in ignores:
                if modname.startswith(ignore):
                    modname = modname[len(ignore):]
                    stripped = ignore
                    break
            else:
                stripped = ''

            # we stripped the whole package name?
            if not modname:
                modname, stripped = stripped, ''

            entries = content.setdefault(modname[0].lower(), [])

            package = modname.split('.')[0]
            if package != modname:
                # it's a subpackage
                if prev_modname == package:
                    # first subpackage - make parent a group head
                    if entries:
                        entries[-1][1] = 1
                elif not prev_modname.startswith(package):
                    # subpackage without parent in list, add dummy entry
                    entries.append([stripped + package, 1, '', '', '', '', ''])
                subtype = 2
            else:
                num_toplevels += 1
                subtype = 0

            qualifier = deprecated and _('Deprecated') or ''
            entries.append([stripped + modname, subtype, docname,
                            'package-' + stripped + modname, platforms,
                            qualifier, synopsis])
            prev_modname = modname

        # apply heuristics when to collapse pkgindex at page load:
        # only collapse if number of toplevel packages is larger than
        # number of subpackages
        collapse = len(packages) - num_toplevels < num_toplevels

        # sort by first letter
        content = sorted(content.items())

        return content, collapse

class BsvModuleIndex(Index):
    """
    Index subinterface to provide the Bsv module index.
    """

    name = 'bsvmodules'
    localname = l_('Bsv Module Index')
    shortname = l_('bsvmodules')

    def generate(self, docnames=None):
        content = {}
        # list of prefixes to ignore
        ignores = self.domain.env.config['pkgindex_common_prefix']
        ignores = sorted(ignores, key=len, reverse=True)
        # list of all packages, sorted by package name
        modules = sorted(self.domain.data['modules'].items(),
                         key=lambda x: x[0].lower())
        # sort out collapsable modules
        prev_modname = ''
        num_toplevels = 0
        for modname, (docname, synopsis, platforms, deprecated) in modules:
            if docnames and docname not in docnames:
                continue

            for ignore in ignores:
                if modname.startswith(ignore):
                    modname = modname[len(ignore):]
                    stripped = ignore
                    break
            else:
                stripped = ''

            # we stripped the whole module name?
            if not modname:
                modname, stripped = stripped, ''

            entries = content.setdefault(modname[0].lower(), [])

            module = modname.split('.')[0]
            if module != modname:
                # it's a submodule
                if prev_modname == module:
                    # first submodule - make parent a group head
                    if entries:
                        entries[-1][1] = 1
                elif not prev_modname.startswith(module):
                    # submodule without parent in list, add dummy entry
                    entries.append([stripped + module, 1, '', '', '', '', ''])
                subtype = 2
            else:
                num_toplevels += 1
                subtype = 0

            qualifier = deprecated and _('Deprecated') or ''
            entries.append([stripped + modname, subtype, docname,
                            'module-' + stripped + modname, platforms,
                            qualifier, synopsis])
            prev_modname = modname

        # apply heuristics when to collapse pkgindex at page load:
        # only collapse if number of toplevel modules is larger than
        # number of submodules
        collapse = len(modules) - num_toplevels < num_toplevels

        # sort by first letter
        content = sorted(content.items())

        return content, collapse


class BsvDomain(Domain):
    """Bsv language domain."""
    name = 'bsv'
    label = 'Bsv'
    object_types = {
        'function':     ObjType(l_('function'),      'func', 'obj'),
        'data':         ObjType(l_('data'),          'data', 'obj'),
        'interface':        ObjType(l_('interface'),         'interface', 'exc', 'obj'),
        'instance':     ObjType(l_('instance'),         'instance', 'obj'),
        'exception':    ObjType(l_('exception'),     'exc', 'interface', 'obj'),
        'method':       ObjType(l_('method'),        'meth', 'obj'),
        'subinterface': ObjType(l_('subinterface'),  'ifc', 'obj'),
        'field': ObjType(l_('field'),  'fld', 'obj'),
        'interfacemethod':  ObjType(l_('interface method'),  'meth', 'obj'),
        'staticmethod': ObjType(l_('static method'), 'meth', 'obj'),
        'package':       ObjType(l_('package'),      'pkg', 'obj'),
        'module':       ObjType(l_('module'),        'mod', 'obj'),
        'struct':        ObjType(l_('struct'),       'struct', 'obj'),
        'typedef':       ObjType(l_('typedef'),      'mod', 'obj'),
        'typeclass':        ObjType(l_('typeclass'),         'typeclass', 'obj'),
    }

    directives = {
        'function':        BsvPackagelevel,
        'data':            BsvPackagelevel,
        'module':          BsvPackagelevel,
        'typedef':         BsvPackagelevel,
        'interface':       BsvInterfacelike,
        'typeclass':       BsvInterfacelike,
        'instance':        BsvInterfacelike,
        'struct':          BsvInterfacelike,
        'method':          BsvInterfacemember,
        'interfacemethod':     BsvInterfacemember,
        'staticmethod':    BsvInterfacemember,
        'subinterface':    BsvInterfacemember,
        'field':           BsvInterfacemember,
        'package':          BsvPackage,
        'currentpackage':   BsvCurrentPackage,
        'decorator':       BsvDecoratorFunction,
        'decoratormethod': BsvDecoratorMethod,
    }
    roles = {
        'data':  BsvXRefRole(),
        'exc':   BsvXRefRole(),
        'func':  BsvXRefRole(fix_parens=True),
        'interface': BsvXRefRole(),
        'const': BsvXRefRole(),
        'attr':  BsvXRefRole(),
        'meth':  BsvXRefRole(fix_parens=True),
        'mod':   BsvXRefRole(),
        'pkg':   BsvXRefRole(),
        'obj':   BsvXRefRole(),
    }
    initial_data = {
        'objects': {},  # fullname -> docname, objtype
        'packages': {},  # modname -> docname, synopsis, platform, deprecated
        'modules': {},  # modname -> docname, synopsis, platform, deprecated
        'labels': {         # labelname -> docname, labelid, sectionname
            'pkgindex': ('bsv-pkgindex', '', l_('Package Index')),
        },
        'anonlabels': {     # labelname -> docname, labelid
            'pkgindex': ('bsv-pkgindex', ''),
        },
    }
    indices = [
        BsvPackageIndex,
        BsvModuleIndex
    ]

    def clear_doc(self, docname):
        for fullname, (fn, _) in self.data['objects'].items():
            if fn == docname:
                del self.data['objects'][fullname]
        for modname, (fn, _, _, _) in self.data['packages'].items():
            if fn == docname:
                del self.data['packages'][modname]

    def find_obj(self, env, modname, interfacename, name, type, searchmode=0):
        """Find a Bsv object for "name", perhaps using the given package
        and/or interfacename.  Returns a list of (name, object entry) tuples.
        """
        # skip parens
        if name[-2:] == '()':
            name = name[:-2]

        if not name:
            return []

        objects = self.data['objects']
        matches = []

        newname = None
        if searchmode == 1:
            objtypes = self.objtypes_for_role(type)
            if objtypes is not None:
                if modname and interfacename:
                    fullname = modname + '::' + interfacename + '.' + name
                    if fullname in objects and objects[fullname][1] in objtypes:
                        newname = fullname
                if not newname:
                    if modname and modname + '::' + name in objects and \
                       objects[modname + '::' + name][1] in objtypes:
                        newname = modname + '::' + name
                    elif name in objects and objects[name][1] in objtypes:
                        newname = name
                    else:
                        # "fuzzy" searching mode
                        searchname = '.' + name
                        matches = [(oname, objects[oname]) for oname in objects
                                   if oname.endswith(searchname)
                                   and objects[oname][1] in objtypes]
        else:
            # NOTE: searching for exact match, object type is not considered
            if name in objects:
                newname = name
            elif type == 'mod':
                # only exact matches allowed for packages
                return []
            elif interfacename and interfacename + '.' + name in objects:
                newname = interfacename + '.' + name
            elif modname and modname + '::' + name in objects:
                newname = modname + '::' + name
            elif modname and interfacename and \
                     modname + '::' + interfacename + '.' + name in objects:
                newname = modname + '::' + interfacename + '.' + name
            # special case: builtin exceptions have package "exceptions" set
            elif type == 'exc' and '.' not in name and \
                 'exceptions.' + name in objects:
                newname = 'exceptions.' + name
            # special case: object methods
            elif type in ('func', 'meth') and '.' not in name and \
                 'object.' + name in objects:
                newname = 'object.' + name
        if newname is not None:
            matches.append((newname, objects[newname]))
        return matches

    def resolve_xref(self, env, fromdocname, builder,
                     type, target, node, contnode):
        modname = node.get('bsv:package')
        clsname = node.get('bsv:interface')
        searchmode = node.hasattr('refspecific') and 1 or 0
        matches = self.find_obj(env, modname, clsname, target,
                                type, searchmode)
        if not matches:
            return None
        elif len(matches) > 1:
            env.warn_node(
                'more than one target found for cross-reference '
                '%r: %s' % (target, ', '.join(match[0] for match in matches)),
                node)
        name, obj = matches[0]

        if obj[1] == 'package':
            # get additional info for packages
            docname, synopsis, platform, deprecated = self.data['packages'][name]
            assert docname == obj[0]
            title = name
            if synopsis:
                title += ': ' + synopsis
            if deprecated:
                title += _(' (deprecated)')
            if platform:
                title += ' (' + platform + ')'
            return make_refnode(builder, fromdocname, docname,
                                'package-' + name, contnode, title)
        else:
            return make_refnode(builder, fromdocname, obj[0], name,
                                contnode, name)

    def get_objects(self):
        for modname, info in self.data['packages'].items():
            yield (modname, modname, 'package', info[0], 'package-' + modname, 0)
        for refname, (docname, type) in self.data['objects'].items():
            if type != 'package':  # packages are already handled
                yield (refname, refname, type, docname, refname, 1)

def setup(app):
    print('sphinxbsv setup')
    app.add_config_value('bsv_include_bsvs', False, False)
    app.add_config_value('add_package_names', True, True)
    app.add_config_value('pkgindex_common_prefix', [], 'html')

    app.add_domain(BsvDomain)
