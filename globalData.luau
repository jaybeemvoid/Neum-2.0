local globalExports = {}
globalExports.currentContext = nil
globalExports.currentActiveScope = nil

globalExports.debug = true
globalExports.optimize = false

globalExports.__trait_silent  = 1 -- allows derived values to re-evaluate while not informing dependants of the change
globalExports.__trait_internal = 2 -- bypasses instance checks for internal use like the reactive utils

globalExports.componentScopes = {}

return globalExports