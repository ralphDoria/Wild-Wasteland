export type itemEntry = {
    LayoutOrder: number, 
    tool: Tool
}

export type StandardLootableObject = {
    Space: number,
    items: {
        [number]: {
            tool: Tool?,
            isGrabbed: boolean
        }
    }
}

export type dataChangeRequestPacket = {
    LayoutOrder: number,
    syncCheck: Tool?,
    newTool: Tool?
}

export type dropRequest_Data = {

}

return nil