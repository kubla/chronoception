from pathlib import Path
import hashlib
import json
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'Chronoception.xcodeproj'
objects = {}

class Ref(str):
    pass

def identity(name):
    return Ref(hashlib.sha256(name.encode()).hexdigest()[:24].upper())

def add(key_name, kind, **fields):
    key = identity(key_name)
    objects[key] = dict(isa=kind, **fields)
    return key

def render(value, indent=0):
    if isinstance(value, Ref): return value
    if isinstance(value, str): return json.dumps(value)
    if isinstance(value, int): return str(value)
    if isinstance(value, list): return '(' + ', '.join(render(v, indent) for v in value) + ')'
    lines = ['{']
    for key, item in value.items():
        lines.append('\t' * (indent + 1) + str(key) + ' = ' + render(item, indent + 1) + ';')
    lines.append('\t' * indent + '}')
    return '\n'.join(lines)

application = [p.relative_to(ROOT).as_posix() for p in sorted((ROOT / 'Application').glob('*.swift'))]
file_refs = {path: add('file:' + path, 'PBXFileReference', lastKnownFileType='sourcecode.swift', path=Path(path).name, sourceTree='<group>') for path in application}
ui_path = 'UITests/PracticeUITests.swift'
ui_ref = add('file:' + ui_path, 'PBXFileReference', lastKnownFileType='sourcecode.swift', path='PracticeUITests.swift', sourceTree='<group>')
assets = add('file:assets', 'PBXFileReference', lastKnownFileType='folder.assetcatalog', path='Assets.xcassets', sourceTree='<group>')
app_group = add('group:Application', 'PBXGroup', children=list(file_refs.values()) + [assets], path='Application', sourceTree='<group>')
ui_group = add('group:UITests', 'PBXGroup', children=[ui_ref], path='UITests', sourceTree='<group>')
shared_group = add('group:Shared', 'PBXFileReference', lastKnownFileType='folder', path='Shared', sourceTree='<group>')
package = add('package:Shared', 'XCLocalSwiftPackageReference', relativePath='Shared')
project_id = identity('project')
products = []
target_ids = {name: identity('target:' + name) for name in ['Chronoception', 'ChronoceptionWatch', 'ChronoceptionUITests', 'ChronoceptionWatchUITests']}


def configurations(name, base, project=False):
    refs=[]
    for mode in ['Debug','Release']:
        settings = dict(base)
        settings.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if mode=='Debug' else '-O', DEBUG_INFORMATION_FORMAT='dwarf' if mode=='Debug' else 'dwarf-with-dsym')
        if mode=='Debug': settings.update(SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG $(inherited)', ENABLE_TESTABILITY='YES')
        refs.append(add('config:'+name+mode, 'XCBuildConfiguration', buildSettings=settings, name=mode))
    return add('configs:'+name, 'XCConfigurationList', buildConfigurations=refs, defaultConfigurationIsVisible=0, defaultConfigurationName='Release')


def make_target(name, watch=False, test=False):
    bundle = 'io.mjjt.chronoception' + ('.watchkitapp' if watch else '') + ('.uitests' if test else '')
    product_name = name + ('.xctest' if test else '.app')
    product = add('product:'+name, 'PBXFileReference', explicitFileType='wrapper.cfbundle' if test else 'wrapper.application', includeInIndex=0, path=product_name, sourceTree='BUILT_PRODUCTS_DIR')
    products.append(product)
    sources = [add('source:'+name+':'+p, 'PBXBuildFile', fileRef=r) for p,r in (([(ui_path,ui_ref)]) if test else file_refs.items())]
    phases=[add('sources:'+name,'PBXSourcesBuildPhase',buildActionMask=2147483647,files=sources,runOnlyForDeploymentPostprocessing=0)]
    package_products=[]
    frameworks=[]
    if not test:
        for module in ['ChronoceptionCore','ChronoceptionStorage']:
            dependency=add('package-product:'+name+module,'XCSwiftPackageProductDependency',package=package,productName=module)
            package_products.append(dependency)
            frameworks.append(add('framework:'+name+module,'PBXBuildFile',productRef=dependency))
    phases.append(add('frameworks:'+name,'PBXFrameworksBuildPhase',buildActionMask=2147483647,files=frameworks,runOnlyForDeploymentPostprocessing=0))
    resources=[] if test else [add('resource:'+name,'PBXBuildFile',fileRef=assets)]
    phases.append(add('resources:'+name,'PBXResourcesBuildPhase',buildActionMask=2147483647,files=resources,runOnlyForDeploymentPostprocessing=0))
    dependencies=[]
    dependency_name=('ChronoceptionWatch' if watch else 'Chronoception') if test else ('ChronoceptionWatch' if not watch else None)
    if dependency_name:
        proxy=add('proxy:'+name,'PBXContainerItemProxy',containerPortal=project_id,proxyType=1,remoteGlobalIDString=target_ids[dependency_name],remoteInfo=dependency_name)
        dependencies.append(add('dependency:'+name,'PBXTargetDependency',target=target_ids[dependency_name],targetProxy=proxy))
    if not test and not watch:
        embedded=add('embed-watch','PBXBuildFile',fileRef=identity('product:ChronoceptionWatch'),settings={'ATTRIBUTES':['RemoveHeadersOnCopy']})
        phases.append(add('watch-copy','PBXCopyFilesBuildPhase',buildActionMask=2147483647,dstPath='$(CONTENTS_FOLDER_PATH)/Watch',dstSubfolderSpec=16,files=[embedded],name='Embed Watch Content',runOnlyForDeploymentPostprocessing=0))
    settings=dict(PRODUCT_BUNDLE_IDENTIFIER=bundle, PRODUCT_NAME='$(TARGET_NAME)', SWIFT_VERSION='6.0', SWIFT_STRICT_CONCURRENCY='complete', GENERATE_INFOPLIST_FILE='YES', CODE_SIGN_STYLE='Automatic', CURRENT_PROJECT_VERSION='1', MARKETING_VERSION='0.1.0', ENABLE_USER_SCRIPT_SANDBOXING='YES', TARGETED_DEVICE_FAMILY='4' if watch else '1', SDKROOT='watchos' if watch else 'iphoneos', SUPPORTED_PLATFORMS='watchos watchsimulator' if watch else 'iphoneos iphonesimulator')
    settings['WATCHOS_DEPLOYMENT_TARGET' if watch else 'IPHONEOS_DEPLOYMENT_TARGET']='10.0' if watch else '17.0'
    if test:
        settings['TEST_TARGET_NAME']='ChronoceptionWatch' if watch else 'Chronoception'
    else:
        settings.update(INFOPLIST_KEY_CFBundleDisplayName='Chronoception', ASSETCATALOG_COMPILER_APPICON_NAME='AppIconWatch' if watch else 'AppIcon', ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME='AccentColor', SWIFT_EMIT_LOC_STRINGS='YES')
        if watch:
            settings.update(INFOPLIST_KEY_WKApplication='YES', INFOPLIST_KEY_WKCompanionAppBundleIdentifier='io.mjjt.chronoception', INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp='YES')
        else:
            settings.update(INFOPLIST_KEY_UILaunchScreen_Generation='YES', INFOPLIST_KEY_UIApplicationSceneManifest_Generation='YES', INFOPLIST_KEY_UISupportedInterfaceOrientations='UIInterfaceOrientationPortrait')
    add('target:'+name,'PBXNativeTarget',buildConfigurationList=configurations(name,settings),buildPhases=phases,buildRules=[],dependencies=dependencies,name=name,packageProductDependencies=package_products,productName=name,productReference=product,productType='com.apple.product-type.bundle.ui-testing' if test else 'com.apple.product-type.application')

for name,watch,test in [('Chronoception',False,False),('ChronoceptionWatch',True,False),('ChronoceptionUITests',False,True),('ChronoceptionWatchUITests',True,True)]:
    make_target(name,watch,test)
products_group=add('group:Products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main=add('group:Main','PBXGroup',children=[app_group,shared_group,ui_group,products_group],sourceTree='<group>')
add('project','PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1600','TargetAttributes':{target_ids[n]:{'CreatedOnToolsVersion':'16.0',**({'TestTargetID':target_ids['ChronoceptionWatch' if 'Watch' in n else 'Chronoception']} if 'UITests' in n else {})}for n in target_ids}},buildConfigurationList=configurations('Project',{'CLANG_ENABLE_MODULES':'YES','SWIFT_VERSION':'6.0'}),compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=main,packageReferences=[package],productRefGroup=products_group,projectDirPath='',projectRoot='',targets=list(target_ids.values()))
root=dict(archiveVersion=1,classes={},objectVersion=56,objects=objects,rootObject=project_id)
outputs={PROJECT/'project.pbxproj':'// !$*UTF8*$!\n'+render(root)+'\n'}

for name in ['Chronoception','ChronoceptionWatch']:
    scheme=ET.Element('Scheme',LastUpgradeVersion='1600',version='1.3')
    build=ET.SubElement(scheme,'BuildAction',parallelizeBuildables='YES',buildImplicitDependencies='YES')
    entries=ET.SubElement(build,'BuildActionEntries')
    test_name=name+'UITests'
    def reference(parent,target):
        ET.SubElement(parent,'BuildableReference',BuildableIdentifier='primary',BlueprintIdentifier=target_ids[target],BuildableName=target+('.xctest' if 'UITests' in target else '.app'),BlueprintName=target,ReferencedContainer='container:Chronoception.xcodeproj')
    for target in [name,test_name]:
        entry=ET.SubElement(entries,'BuildActionEntry',buildForTesting='YES',buildForRunning='NO' if 'UITests' in target else 'YES',buildForProfiling='NO' if 'UITests' in target else 'YES',buildForArchiving='NO' if 'UITests' in target else 'YES',buildForAnalyzing='YES')
        reference(entry,target)
    action=ET.SubElement(scheme,'TestAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',shouldUseLaunchSchemeArgsEnv='YES')
    testable=ET.SubElement(ET.SubElement(action,'Testables'),'TestableReference',skipped='NO')
    reference(testable,test_name)
    launch=ET.SubElement(scheme,'LaunchAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',launchStyle='0',useCustomWorkingDirectory='NO',ignoresPersistentStateOnLaunch='NO',debugDocumentVersioning='YES',debugServiceExtension='internal',allowLocationSimulation='YES')
    reference(ET.SubElement(launch,'BuildableProductRunnable',runnableDebuggingMode='0'),name)
    profile=ET.SubElement(scheme,'ProfileAction',buildConfiguration='Release',shouldUseLaunchSchemeArgsEnv='YES',savedToolIdentifier='',useCustomWorkingDirectory='NO',debugDocumentVersioning='YES')
    reference(ET.SubElement(profile,'BuildableProductRunnable',runnableDebuggingMode='0'),name)
    ET.SubElement(scheme,'AnalyzeAction',buildConfiguration='Debug')
    ET.SubElement(scheme,'ArchiveAction',buildConfiguration='Release',revealArchiveInOrganizer='YES')
    ET.indent(scheme)
    outputs[PROJECT/'xcshareddata'/'xcschemes'/(name+'.xcscheme')]='<?xml version="1.0" encoding="UTF-8"?>\n'+ET.tostring(scheme,encoding='unicode')+'\n'

if '--check' in sys.argv:
    different=[str(p.relative_to(ROOT)) for p,text in outputs.items() if not p.exists() or p.read_text()!=text]
    if different: raise SystemExit('Regenerate project: '+', '.join(different))
else:
    for path,text in outputs.items():
        path.parent.mkdir(parents=True,exist_ok=True)
        path.write_text(text)
    print('Generated native phone/Watch targets and UI-test schemes without third-party project generators.')
