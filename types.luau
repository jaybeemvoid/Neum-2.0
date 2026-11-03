--strict

export type As<T> = Dependency<T> | ValueStream<T> | T

export type Map<I, V> = {[I] : V}

export type Props<PI, PV> = Map<PI, PV>

export type Dependency<T> = {
	__type: "Dependency",
	Set: (self: Dependency<T>, newValue: ((prevValue: T) -> T) | T) -> (),
	Get: (self: Dependency<T>) -> T,
	Peek: (self: Dependency<T>) -> T,
}

export type InternalDependency<T> = Dependency<T> & {
	_dependants: {[ValueStream<unknown>] : true},
	_value: T,
	_traits: number,
	_immutable_ref: Unmutref<T>,

	--intern methods
	_addTrait: (self: Dependency<T>, trait : number) -> (),
	Destroy: (self: Dependency<T>) -> (),
}

export type Unmutref<T> = {
	Peek: (self: Unmutref<T>) -> T,
	Get: (self: Unmutref<T>) -> T,
}

export type Pointer<T> = {
	__type: "Pointer",
	Get: (self: Pointer<T>) -> T,
}

export type ValueStream<T> = {
	__type: "ValueStream",
	Set: (self: ValueStream<T>) -> (),
	Get: (self: ValueStream<T>) -> T,
	Peek: (self: ValueStream<T>) -> T,
}

export type InternalValueStream<T> = ValueStream<T> & {
	_fn : () -> T,
	_dependants: {[ValueStream<T>] : true},
	_dependOn : {[Dependency<T>] : true},
	_value: T?,
	_uiUpdates: {(newValue : unknown) -> ()},
	_scope: InternalScope,

	--intern methods
	run: (self: ValueStream<T>, traits : number) -> (),
	evaluate: (self: ValueStream<T>, node: ValueStream<unknown>) -> (),
	__register: (self: ValueStream<T>, stream: ValueStream<unknown>) -> (),
	listen: (self: ValueStream<T>, callback: (newValue : T) -> ()) -> (),
	__getScope: (self: ValueStream<T>) -> InternalScope,
	Destroy: (self: ValueStream<T>) -> (),
}

export type Scope = {
	__type: "Scope",
	Clear: (self: Scope) -> (),
	newSubScope: (self: Scope, fn: () -> Instance) -> Scope,
}

export type InternalScope = Scope & {
	_childScopes: {[InternalScope] : boolean},
	_parentScope: InternalScope?,
	_cleanups: {RBXScriptConnection | Instance | () -> ()},

	--intern methods
	__register : (self: Scope, object: Instance | ValueStream<unknown> | Dependency<unknown> | RBXScriptConnection | () -> ()) -> (),
}

export type SpecialKey = {
	__type: "SpecialKey",
	eventName: string,
	phase: number,
	apply: (self: Scope, instance: Instance, callback: (...unknown) -> (...unknown)) -> ()
}

export type Instances = {
	Frame: Frame,
	TextLabel: TextLabel,
	TextButton: TextButton,
	UICorner: UICorner,
	UIGradient: UIGradient,
	UIListLayout: UIListLayout,
	UIGridLayout: UIGridLayout,
	UIPadding: UIPadding,
	UIStroke: UIStroke,
	UIConstraint: UIConstraint,
	UIScale: UIScale,
	UIShadow: UIShadow,
	UIFlexItem: UIFlexItem,
	UIPageLayout: UIPageLayout,
	UITableLayout: UITableLayout,
	UISizeConstraint: UISizeConstraint,
	UITextSizeConstraint: UITextSizeConstraint,
	TextBox: TextBox,
	ScreenGui: ScreenGui,
	CanvasGroup: CanvasGroup,
	Model: Model,
	Folder: Folder,
}

export type function Properties(instance_type)
	local properties = types.newtable()

	while instance_type do
		for property_name, property_data in instance_type:properties() do
			if property_data.write then
				properties:setproperty(property_name, types.optional(types.unionof(
					property_data.write,
					types.newtable(),
					types.newfunction({}, {})
					)))
			end
		end
		instance_type = instance_type:readparent()
	end


	properties:setindexer(types.number, types.any)
	return properties
end

export type CreateFn = <ClassName>(ClassName & keyof<Instances>) -> (Properties<index<Instances, ClassName>>?) -> index<Instances, ClassName>

type Component<I, P> = {
	__type: "Component",
} & ((P) -> I)

export type Component_Constructor = <I, P>(Callback : (P) -> I) -> Component<I, P>

return nil