
export async function getContractSourceCode(contractAddress: string) {
    // Arbiscan API endpoint
    const baseUrl = 'https://api-sepolia.etherscan.io/api';
        
    // Build URL with query parameters
    const url = new URL(baseUrl);
    url.searchParams.append('module', 'contract');
    url.searchParams.append('action', 'getsourcecode');
    url.searchParams.append('address', contractAddress);
    url.searchParams.append('apikey', process.env.EXPLORER_API_KEY!);
    try {
        // Make API request using fetch
        const response = await fetch(url.toString());
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const result = await response.json();
        
        // Check if request was successful
        if (result.status === '1' && result.message === 'OK') {
            const contractData = result.result[0];
            
            // Return relevant contract information
            return {
                sourceCode: contractData.SourceCode,
                contractName: contractData.ContractName,
                compilerVersion: contractData.CompilerVersion,
                optimizationUsed: contractData.OptimizationUsed,
                isVerified: contractData.ABI !== 'Contract source code not verified'
            };
        } else {
            throw new Error(`API Error: ${result.message}`);
        }
    } catch (error: any) {
        console.error('Error fetching contract source code:', error.message);
        throw error;
    }
}
