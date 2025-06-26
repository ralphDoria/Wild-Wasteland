export type itemEntry = {
    LayoutOrder: number, 
    tool: Tool
}

export type StandardLootableObjectItems = {
    [number]: {
        tool: Tool?,
        isGrabbed: boolean
    }
}

export type StandardLootableObject = {
    Space: number,
    items: StandardLootableObjectItems
}

export type dataChangeRequestPacket = {
    LayoutOrder: number,
    syncCheck: Tool?,
    newTool: Tool?
}

export type dropRequest_Data = {

}

return nil