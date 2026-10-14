extends RefCounted
class_name PieceDefs

const SHAPES = [
	{"w": 1, "h": 1, "cells": [Vector2i(0, 0)]},
	{"w": 2, "h": 1, "cells": [Vector2i(0, 0), Vector2i(1, 0)]},
	{"w": 1, "h": 2, "cells": [Vector2i(0, 0), Vector2i(0, 1)]},
	{"w": 3, "h": 1, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]},
	{"w": 1, "h": 3, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]},
	{"w": 4, "h": 1, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]},
	{"w": 1, "h": 4, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]},
	{"w": 5, "h": 1, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]},
	{"w": 1, "h": 5, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)]},
	{"w": 2, "h": 2, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]},
	{"w": 2, "h": 3, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]},
	{"w": 3, "h": 2, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]},
	{"w": 2, "h": 2, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]},
	{"w": 2, "h": 2, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]},
	{"w": 2, "h": 2, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"w": 2, "h": 2, "cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(0, 2)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 0)]},
	{"w": 3, "h": 3, "cells": [Vector2i(2, 0), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]},
	{"w": 3, "h": 3, "cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]},
	{"w": 3, "h": 3, "cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 1)]},
	{"w": 3, "h": 3, "cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]},
]

static func random_shape(rng: RandomNumberGenerator) -> Dictionary:
	return SHAPES[rng.randi_range(0, SHAPES.size() - 1)]
