-- TYPE DEFINITIONS

export type Point = {
	x: number,
	y: number
}

export type Array<T> = { [number]: T }

export type QuadEdge = typeof(setmetatable({}, _quadEdgeCache)) & {
	onext: QuadEdge,
	mark: boolean,
	orig: Point,
	rot: QuadEdge
}

return {}
