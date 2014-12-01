
import re
from copy import deepcopy

from six import iteritems, text_type
from docutils import nodes

from sphinx import addnodes
from sphinx.roles import XRefRole
from sphinx.locale import l_, _
from sphinx.domains import Domain, ObjType, Index
from sphinx.directives import ObjectDescription
from sphinx.util.nodes import make_refnode
from sphinx.util.compat import Directive
#from sphinx.util.pycompat import UnicodeMixin
from sphinx.util.docfields import Field, GroupedField

from docutils import nodes
from docutils.parsers.rst import directives

class bsv(nodes.Admonition, nodes.Element):
    pass

class bsvlist(nodes.General, nodes.Element):
    pass

def visit_bsv_node(self, node):
    self.visit_admonition(node)

def depart_bsv_node(self, node):
    self.depart_admonition(node)

from docutils.parsers.rst import Directive

class BsvlistDirective(Directive):

    def run(self):
        return [bsvlist('')]

from sphinx.util.compat import make_admonition

class BsvDirective(Directive):

    # this enables content in the directive
    has_content = True

    def run(self):
        env = self.state.document.settings.env

        targetid = "bsv-%d" % env.new_serialno('bsv')
        targetnode = nodes.target('', '', ids=[targetid])

        ad = make_admonition(bsv, self.name, [_('Bsv')], self.options,
                             self.content, self.lineno, self.content_offset,
                             self.block_text, self.state, self.state_machine)

        if not hasattr(env, 'bsv_all_bsvs'):
            env.bsv_all_bsvs = []
        env.bsv_all_bsvs.append({
            'docname': env.docname,
            'lineno': self.lineno,
            'bsv': ad[0].deepcopy(),
            'target': targetnode,
        })

        return [targetnode] + ad

def purge_bsvs(app, env, docname):
    if not hasattr(env, 'bsv_all_bsvs'):
        return
    env.bsv_all_bsvs = [bsv for bsv in env.bsv_all_bsvs
                          if bsv['docname'] != docname]

def process_bsv_nodes(app, doctree, fromdocname):
    if not app.config.bsv_include_bsvs:
        for node in doctree.traverse(bsv):
            node.parent.remove(node)

    # Replace all bsvlist nodes with a list of the collected bsvs.
    # Augment each bsv with a backlink to the original location.
    env = app.builder.env

    for node in doctree.traverse(bsvlist):
        if not app.config.bsv_include_bsvs:
            node.replace_self([])
            continue

        content = []

        for bsv_info in env.bsv_all_bsvs:
            para = nodes.paragraph()
            filename = env.doc2path(bsv_info['docname'], base=None)
            description = (
                _('(The original entry is located in %s, line %d and can be found ') %
                (filename, bsv_info['lineno']))
            para += nodes.Text(description, description)

            # Create a reference
            newnode = nodes.reference('', '')
            innernode = nodes.emphasis(_('here'), _('here'))
            newnode['refdocname'] = bsv_info['docname']
            newnode['refuri'] = app.builder.get_relative_uri(
                fromdocname, bsv_info['docname'])
            newnode['refuri'] += '#' + bsv_info['target']['refid']
            newnode.append(innernode)
            para += newnode
            para += nodes.Text('.)', '.)')

            # Insert into the bsvlist
            content.append(bsv_info['bsv'])
            content.append(para)

        node.replace_self(content)

class BSVObject(ObjectDescription):
    """Description of a BSV language object."""

    doc_field_types = [
        GroupedField('parameter', label=l_('Parameters'),
                     names=('param', 'parameter', 'arg', 'argument'),
                     can_collapse=True),
        Field('returntype', label=l_('Returns'), has_arg=False,
              names=('returns', 'return')),
    ]

    def get_signatures(self):
        print 'BSVObject.get_signatures', self.name, self.domain
        name = self.arguments[0]
        parameters = ''
        if self.options.has_key('parameter'):
            parameters = ' '.join('\n'.split(self.options['parameter']))
        name = '%s %s' % (self.objtype,  name)
        return [name]

    def add_target_and_index(self, name_obj, sig, signode):
        print 'BSVObject.add_target_and_index', name_obj, sig, signode
        objects = self.env.domaindata['bsv']['objects']
        objects[fullname] = self.env.docname, self.objtype

class BSVTypeObject(BSVObject):
    def get_index_text(self, name):
        return _('%s (BSV type)') % name

    def parse_definition(self, parser):
        return parser.parse_type_object()

    def describe_signature(self, signode, ast):
        signode += addnodes.desc_annotation('type ', 'type ')
        ast.describe_signature(signode, 'lastIsName', self.env)

class BSVMethodObject(BSVObject):
    option_spec = {
        'returntype': directives.unchanged_required,
        'parameter': directives.unchanged_required
        }
    def get_signatures(self):
        print 'BSVObject.get_signatures', self.name, self.domain
        name = self.arguments[0]
        returntype = ''
        print self.options
        if self.options.has_key('returntype'):
            returntype = self.options['returntype']
        parameters = ''
        if self.options.has_key('parameter'):
            parameters = ', '.join(self.options['parameter'].split('\n'))
        print parameters
        name = '%s %s %s(%s)' % (self.objtype, returntype, name, parameters)
        return [name]

    def get_index_text(self, name):
        print 'BSVMethodObject.get_index_text', name
        return _('%s (BSV method)') % name

    def parse_definition(self, parser):
        return parser.parse_member_object()

    def describe_signature(self, signode, ast):
        ast.describe_signature(signode, 'lastIsName', self.env)


class BSVFunctionObject(BSVObject):
    def get_index_text(self, name):
        return _('%s (BSV function)') % name

    def parse_definition(self, parser):
        return parser.parse_function_object()

    def describe_signature(self, signode, ast):
        ast.describe_signature(signode, 'lastIsName', self.env)

class BSVModuleObject(BSVObject):
    def get_index_text(self, name):
        return _('%s (BSV module)') % name

class BSVInterfaceObject(BSVObject):
    def get_index_text(self, name):
        return _('%s (BSV module)') % name

class BSVPackageObject(Directive):
    """
    This directive is just to tell Sphinx that we're documenting stuff in
    namespace foo.
    """

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = True
    option_spec = {}

    def run(self):
        env = self.state.document.settings.env
        if self.arguments[0].strip() in ('NULL', '0', 'nullptr'):
            env.temp_data['bsv:prefix'] = None
        else:
            parser = DefinitionParser(self.arguments[0])
            try:
                prefix = parser.parse_type()
                parser.assert_end()
            except DefinitionError, e:
                self.state_machine.reporter.warning(e.description,
                                                    line=self.lineno)
            else:
                env.temp_data['bsv:prefix'] = prefix
        return []

class BSVXRefRole(XRefRole):
    def process_link(self, env, refnode, has_explicit_title, title, target):
        parent = env.ref_context.get('bsv:parent')
        if parent:
            refnode['bsv:parent'] = parent[:]
        return title, target

class BSVInterfaceIndex(Index):
    """
    An Index is the description for a domain-specific index.  To add an index to
    a domain, subclass Index, overriding the three name attributes:

    * `name` is an identifier used for generating file names.
    * `localname` is the section title for the index.
    * `shortname` is a short name for the index, for use in the relation bar in
      HTML output.  Can be empty to disable entries in the relation bar.

    and providing a :meth:`generate()` method.  Then, add the index class to
    your domain's `indices` list.  Extensions can add indices to existing
    domains using :meth:`~sphinx.application.Sphinx.add_index_to_domain()`.
    """

    name = 'BSV Interfaces'
    localname = 'interfaces'
    shortname = 'interfaces'

    def generate(self):
        print 'BSVInterfaceIndex.generate'
        return [], False
        return [['name', 0, 1, 'anchor', 'extra', 'qualifier', 'description']], False

class BSVDomain(Domain):
    name = 'bsv'
    label = 'BSV'
    object_types = {
        'interface': ObjType(l_('interface'), 'interface'),
        'module': ObjType(l_('module'), 'module'),
        'method': ObjType(l_('method'), 'method'),
        'function': ObjType(l_('function'), 'function'),
        'type': ObjType(l_('type'), 'type'),
        }
    directives = {
        'interface': BSVInterfaceObject,
        'module': BSVModuleObject,
        'method': BSVMethodObject,
        'type': BSVTypeObject,
        'package': BSVPackageObject
    }
    roles = {
        'interface': BSVXRefRole(),
        'module': BSVXRefRole(fix_parens=True),
        'method': BSVXRefRole(),
        'type': BSVXRefRole(),
        'package': BSVXRefRole()
    }
    initial_data = {
        'objects': {},  # prefixedName -> (docname, objectType, id)
        'interfaces': {}
    }
    indices = [
        BSVInterfaceIndex
        ]

    def clear_doc(self, docname):
        for fullname, (fn, _, _) in self.data['objects'].items():
            if fn == docname:
                del self.data['objects'][fullname]

    def resolve_xref(self, env, fromdocname, builder,
                     typ, target, node, contnode):
        print 'BSVDomain.resolve_xref', env, fromdocname, builder, typ, target, node, contnode
        return None

    def get_objects(self):
        print 'BSVDomain.get_objects'
        for refname, (docname, type, theid) in self.data['objects'].iteritems():
            print 'BSVDomain.get_objects', refname, type, docname
            yield (refname, refname, type, docname, refname, 1)

def setup(app):
    print 'sphinxbsv setup'
    app.add_config_value('bsv_include_bsvs', False, False)

    app.add_node(bsvlist)
    app.add_node(bsv,
                 html=(visit_bsv_node, depart_bsv_node),
                 latex=(visit_bsv_node, depart_bsv_node),
                 text=(visit_bsv_node, depart_bsv_node))

    app.add_domain(BSVDomain)
    app.add_directive('bsv', BsvDirective)
    app.add_directive('bsvlist', BsvlistDirective)
    app.connect('doctree-resolved', process_bsv_nodes)
    app.connect('env-purge-doc', purge_bsvs)
