#!/usr/bin/env python3
"""
Generates Soulspring.xcodeproj (project.pbxproj, workspace, shared scheme)
from the Swift/plist files under ./Soulspring/.

Run from the repo root:
    python3 scripts/generate_xcodeproj.py

Idempotent: deletes the existing .xcodeproj first.
"""
from __future__ import annotations
import hashlib
import os
import shutil
import sys
from pathlib import Path

REPO   = Path(__file__).resolve().parent.parent
ROOT   = REPO / "Soulspring"
PROJ   = REPO / "Soulspring.xcodeproj"
APP    = "Soulspring"
BUNDLE = "mx.soulspring.app"
DEPLOY = "17.0"
SWIFT  = "5.0"

# ----- UUID helper ---------------------------------------------------------

def uid(tag: str) -> str:
    """Deterministic 24-hex-char id derived from a tag string."""
    h = hashlib.sha1(tag.encode()).hexdigest().upper()
    return h[:24]

# ----- Collect files -------------------------------------------------------

def collect():
    swift_files, plist_files = [], []
    for path in sorted(ROOT.rglob("*")):
        if path.is_dir():
            continue
        rel = path.relative_to(REPO)
        if path.suffix == ".swift":
            swift_files.append(rel)
        elif path.suffix in (".plist", ".entitlements"):
            plist_files.append(rel)
    return swift_files, plist_files

# ----- Group tree ----------------------------------------------------------

class Group:
    def __init__(self, name, path=None):
        self.name = name
        self.path = path
        self.children_groups: dict[str, Group] = {}
        self.children_files: list[Path] = []
        self.uid = uid(f"group:{name}:{path}")

def build_tree(files):
    root = Group("Soulspring", path="Soulspring")
    for f in files:
        parts = f.parts[1:]  # drop "Soulspring/"
        node = root
        for folder in parts[:-1]:
            if folder not in node.children_groups:
                node.children_groups[folder] = Group(folder, path=folder)
            node = node.children_groups[folder]
        node.children_files.append(f)
    return root

# ----- pbxproj assembly ----------------------------------------------------

def file_type(p: Path) -> str:
    if p.suffix == ".swift":        return "sourcecode.swift"
    if p.suffix == ".plist":        return "text.plist.xml"
    if p.suffix == ".entitlements": return "text.plist.entitlements"
    return "text"

def generate():
    swift, plists = collect()
    all_files = swift + plists
    tree = build_tree(all_files)

    # IDs
    project_id   = uid("project")
    main_group   = uid("mainGroup")
    products_grp = uid("productsGroup")
    frameworks_grp = uid("frameworksGroup")
    app_target   = uid("appTarget")
    target_ref   = uid("targetRef")
    src_phase    = uid("sourcesPhase")
    fw_phase     = uid("frameworksPhase")
    res_phase    = uid("resourcesPhase")
    bc_debug     = uid("bcDebug")
    bc_release   = uid("bcRelease")
    tc_debug     = uid("tcDebug")
    tc_release   = uid("tcRelease")
    proj_list    = uid("projList")
    target_list  = uid("targetList")
    fr_healthkit = uid("fr_healthkit")
    bf_healthkit = uid("bf_healthkit")

    # Per-file IDs
    file_refs = {}     # path -> file ref id
    build_files = {}   # path -> build file id (only for swift)
    for f in all_files:
        file_refs[f] = uid(f"fref:{f}")
    for f in swift:
        build_files[f] = uid(f"bfile:{f}")

    lines = []
    w = lines.append

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")

    # PBXBuildFile
    w("")
    w("/* Begin PBXBuildFile section */")
    for f in swift:
        bf = build_files[f]
        fr = file_refs[f]
        name = f.name
        w(f"\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {name} */; }};")
    w(f"\t\t{bf_healthkit} /* HealthKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fr_healthkit} /* HealthKit.framework */; }};")
    w("/* End PBXBuildFile section */")

    # PBXFileReference
    w("")
    w("/* Begin PBXFileReference section */")
    for f in all_files:
        fr = file_refs[f]
        name = f.name
        ft = file_type(f)
        w(f"\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ft}; path = {name}; sourceTree = \"<group>\"; }};")
    w(f"\t\t{fr_healthkit} /* HealthKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = HealthKit.framework; path = System/Library/Frameworks/HealthKit.framework; sourceTree = SDKROOT; }};")
    w(f"\t\t{app_target} /* {APP}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {APP}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    w("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    w("")
    w("/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{fw_phase} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w(f"\t\t\t\t{bf_healthkit} /* HealthKit.framework in Frameworks */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup — emit recursively
    w("")
    w("/* Begin PBXGroup section */")

    # Main (root) group
    w(f"\t\t{main_group} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{tree.uid} /* Soulspring */,")
    w(f"\t\t\t\t{products_grp} /* Products */,")
    w(f"\t\t\t\t{frameworks_grp} /* Frameworks */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    # Products
    w(f"\t\t{products_grp} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{app_target} /* {APP}.app */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    # Frameworks
    w(f"\t\t{frameworks_grp} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{fr_healthkit} /* HealthKit.framework */,")
    w("\t\t\t);")
    w("\t\t\tname = Frameworks;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    def emit_group(g: Group, is_root: bool):
        w(f"\t\t{g.uid} /* {g.name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        # Subgroups first (alphabetical)
        for sub in sorted(g.children_groups.values(), key=lambda x: x.name):
            w(f"\t\t\t\t{sub.uid} /* {sub.name} */,")
        # Then files
        for f in sorted(g.children_files, key=lambda x: x.name):
            w(f"\t\t\t\t{file_refs[f]} /* {f.name} */,")
        w("\t\t\t);")
        if is_root:
            w(f"\t\t\tpath = {g.path};")
        else:
            w(f"\t\t\tpath = {g.path};")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")
        for sub in g.children_groups.values():
            emit_group(sub, is_root=False)

    emit_group(tree, is_root=True)
    w("/* End PBXGroup section */")

    # PBXNativeTarget
    w("")
    w("/* Begin PBXNativeTarget section */")
    w(f"\t\t{target_ref} /* {APP} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {target_list} /* Build configuration list for PBXNativeTarget \"{APP}\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{src_phase} /* Sources */,")
    w(f"\t\t\t\t{fw_phase} /* Frameworks */,")
    w(f"\t\t\t\t{res_phase} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = ();")
    w("\t\t\tdependencies = ();")
    w(f"\t\t\tname = {APP};")
    w(f"\t\t\tproductName = {APP};")
    w(f"\t\t\tproductReference = {app_target} /* {APP}.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")

    # PBXProject
    w("")
    w("/* Begin PBXProject section */")
    w(f"\t\t{project_id} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1510;")
    w("\t\t\t\tLastUpgradeCheck = 1510;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{target_ref} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {proj_list} /* Build configuration list for PBXProject \"{APP}\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t\tes,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {main_group};")
    w(f"\t\t\tproductRefGroup = {products_grp} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{target_ref} /* {APP} */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")

    # Resources
    w("")
    w("/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{res_phase} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")

    # Sources
    w("")
    w("/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{src_phase} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for f in swift:
        w(f"\t\t\t\t{build_files[f]} /* {f.name} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")

    # Build settings
    info_plist_rel     = "Soulspring/SupportingFiles/Info.plist"
    entitlements_rel   = "Soulspring/SupportingFiles/Soulspring.entitlements"

    project_common = [
        "ALWAYS_SEARCH_USER_PATHS = NO;",
        "CLANG_ANALYZER_NONNULL = YES;",
        "CLANG_ENABLE_MODULES = YES;",
        "CLANG_ENABLE_OBJC_ARC = YES;",
        "CLANG_ENABLE_OBJC_WEAK = YES;",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;",
        "CLANG_WARN_BOOL_CONVERSION = YES;",
        "CLANG_WARN_COMMA = YES;",
        "CLANG_WARN_CONSTANT_CONVERSION = YES;",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;",
        "CLANG_WARN_DOCUMENTATION_COMMENTS = YES;",
        "CLANG_WARN_EMPTY_BODY = YES;",
        "CLANG_WARN_ENUM_CONVERSION = YES;",
        "CLANG_WARN_INFINITE_RECURSION = YES;",
        "CLANG_WARN_INT_CONVERSION = YES;",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;",
        "CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;",
        "CLANG_WARN_STRICT_PROTOTYPES = YES;",
        "CLANG_WARN_SUSPICIOUS_MOVE = YES;",
        "CLANG_WARN_UNREACHABLE_CODE = YES;",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;",
        "COPY_PHASE_STRIP = NO;",
        "ENABLE_STRICT_OBJC_MSGSEND = YES;",
        "GCC_C_LANGUAGE_STANDARD = gnu11;",
        "GCC_NO_COMMON_BLOCKS = YES;",
        "GCC_WARN_64_TO_32_BIT_CONVERSION = YES;",
        "GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;",
        "GCC_WARN_UNDECLARED_SELECTOR = YES;",
        "GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;",
        "GCC_WARN_UNUSED_FUNCTION = YES;",
        "GCC_WARN_UNUSED_VARIABLE = YES;",
        f"IPHONEOS_DEPLOYMENT_TARGET = {DEPLOY};",
        "MTL_FAST_MATH = YES;",
        "SDKROOT = iphoneos;",
        f"SWIFT_VERSION = {SWIFT};",
    ]

    project_debug = project_common + [
        "DEBUG_INFORMATION_FORMAT = dwarf;",
        "ENABLE_TESTABILITY = YES;",
        "GCC_DYNAMIC_NO_PIC = NO;",
        "GCC_OPTIMIZATION_LEVEL = 0;",
        "GCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\");",
        "MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
        "ONLY_ACTIVE_ARCH = YES;",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
        "SWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
    ]

    project_release = project_common + [
        "COPY_PHASE_STRIP = NO;",
        "DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
        "ENABLE_NS_ASSERTIONS = NO;",
        "MTL_ENABLE_DEBUG_INFO = NO;",
        "SWIFT_COMPILATION_MODE = wholemodule;",
        "VALIDATE_PRODUCT = YES;",
    ]

    target_common = [
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;",
        f"CODE_SIGN_ENTITLEMENTS = {entitlements_rel};",
        "CODE_SIGN_STYLE = Automatic;",
        "CURRENT_PROJECT_VERSION = 1;",
        "DEVELOPMENT_TEAM = \"\";",
        "ENABLE_PREVIEWS = YES;",
        "GENERATE_INFOPLIST_FILE = NO;",
        f"INFOPLIST_FILE = {info_plist_rel};",
        "LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\");",
        "MARKETING_VERSION = 1.0;",
        f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE};",
        f"PRODUCT_NAME = \"$(TARGET_NAME)\";",
        "SWIFT_EMIT_LOC_STRINGS = YES;",
        "TARGETED_DEVICE_FAMILY = \"1\";",
    ]

    def emit_bc(uid_, name, settings):
        w(f"\t\t{uid_} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w("\t\t\tbuildSettings = {")
        for s in settings:
            w(f"\t\t\t\t{s}")
        w("\t\t\t};")
        w(f"\t\t\tname = {name};")
        w("\t\t};")

    w("")
    w("/* Begin XCBuildConfiguration section */")
    emit_bc(bc_debug, "Debug", project_debug)
    emit_bc(bc_release, "Release", project_release)
    emit_bc(tc_debug, "Debug", target_common)
    emit_bc(tc_release, "Release", target_common)
    w("/* End XCBuildConfiguration section */")

    # Configuration lists
    w("")
    w("/* Begin XCConfigurationList section */")
    w(f"\t\t{proj_list} /* Build configuration list for PBXProject \"{APP}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{bc_debug} /* Debug */,")
    w(f"\t\t\t\t{bc_release} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w(f"\t\t{target_list} /* Build configuration list for PBXNativeTarget \"{APP}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{tc_debug} /* Debug */,")
    w(f"\t\t\t\t{tc_release} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w("/* End XCConfigurationList section */")

    w("\t};")
    w(f"\trootObject = {project_id} /* Project object */;")
    w("}")

    return "\n".join(lines) + "\n", project_id, target_ref

# ----- Workspace + scheme --------------------------------------------------

WORKSPACE = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""

def scheme_xml(project_id, target_id):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{APP}.app"
               BlueprintName = "{APP}"
               ReferencedContainer = "container:{APP}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{APP}.app"
            BlueprintName = "{APP}"
            ReferencedContainer = "container:{APP}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""

def main():
    if PROJ.exists():
        shutil.rmtree(PROJ)
    PROJ.mkdir()
    pbx, project_id, target_id = generate()
    (PROJ / "project.pbxproj").write_text(pbx)

    ws_dir = PROJ / "project.xcworkspace"
    ws_dir.mkdir()
    (ws_dir / "contents.xcworkspacedata").write_text(WORKSPACE)

    shared = PROJ / "xcshareddata" / "xcschemes"
    shared.mkdir(parents=True)
    (shared / f"{APP}.xcscheme").write_text(scheme_xml(project_id, target_id))

    print(f"Generated {PROJ.relative_to(REPO)}")

if __name__ == "__main__":
    main()
