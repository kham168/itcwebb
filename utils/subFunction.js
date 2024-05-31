export const getIntFlag = (Flag) => 
{
    let numFlag = 0;

    if(Number(Flag) === 1 || String(Flag) === "Active")
    {
        numFlag = 1;
    }

    return numFlag;
}

export const getVarFlag = (Flag) => {
    let varFlg = "Inactive";

    if(Number(Flag) === 1 || String(Flag) === "Active")
    {
        return "Active";
    }

    return varFlg;
}