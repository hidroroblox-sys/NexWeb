--!strict
-- Signal simples (evento local) — não copia tabelas como o BindableEvent.

export type Connection = { Disconnect: (self: Connection) -> () }

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local listeners: { [number]: (T...) -> () } = {}
	local nextId = 0

	local signal = {} :: Signal<T...>

	function signal.Connect(_self: Signal<T...>, callback: (T...) -> ()): Connection
		nextId += 1
		local id = nextId
		listeners[id] = callback
		local connection = {} :: Connection
		function connection.Disconnect(_conn: Connection)
			listeners[id] = nil
		end
		return connection
	end

	function signal.Fire(_self: Signal<T...>, ...: T...)
		for _, callback in listeners do
			task.spawn(callback, ...)
		end
	end

	return signal
end

return Signal
