--!strict
-- Tipos compartilhados entre servidor e cliente (o "retrato" dos dados do jogador).

export type SlotSnapshot = {
	Index: number,
	EggId: string,
	AnimalId: string,
	HatchAt: number, -- os.time() em que o ovo choca
	HatchDuration: number,
	Hatched: boolean,
}

export type Snapshot = {
	Slots: { SlotSnapshot },
	Index: { [string]: boolean }, -- animais já descobertos
	BarnSlots: number,
	CarryCapacity: number,
	SpeedLevel: number,
	Rebirths: number,
}

export type NotifyPayload = {
	Text: string,
	Kind: string, -- "info" | "success" | "warning" | "danger" | "rarity"
	Color: Color3?,
}

export type WaveData = {
	Id: number,
	Type: string,
	Speed: number,
	StartTime: number, -- workspace:GetServerTimeNow()
	StartZ: number,
}

return {}
