using System;
using System.Threading.Tasks;
using Microsoft.ServiceFabric.Services.Remoting;

namespace SimpleApp.SfProd.Contracts
{
  public interface ICpuBurnerService : IService
  {
    Task<int> GetTransactionsPerSecondAsync();

    Task SetTransactionsPerSecondAsync(int transactionsPerSecond);
  }
}
